//  Copyright (c) 2015 Joyy Inc. All rights reserved.

var Async = require('async');
var Boom = require('boom');
var Cache = require('../cache');
var Const = require('../constants');
var Hoek = require('hoek');
var Joi = require('joi');
var Utils = require('../utils');
var _ = require('lodash');

var internals = {};
var selectAll = 'SELECT id, username, avatar, gender, yob, wcnt, score FROM person ';


exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);

    // get person records by ids. auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/person',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                query: {
                    id: Joi.array().single(true).unique().max(Const.PERSON_PER_QUERY).items(Joi.string().regex(/^[0-9]+$/).max(19))
                }
            }
        },
        handler: function (request, reply) {

            var r = request.query;
            var personIds = r.id;

            Async.waterfall([
                function (callback) {

                    Cache.mhgetall(Cache.PersonStore, personIds, function (err, result) {
                        if (err) {
                            console.error(err);
                        }

                        // result is an array, and each element is an array in form of [err, personObj]
                        var foundObjs = _(result).map(_.last).compact().reject(_.isEmpty).value();
                        var foundIds = _.pluck(foundObjs, 'id');
                        var missedIds = _.difference(personIds, foundIds);

                        return callback(null, missedIds, foundObjs);
                    });
                },
                function (missedIds, cachedObjs, callback) {
                    if (_.isEmpty(missedIds)) {
                        return callback(null, cachedObjs);
                    }

                    internals.searchPersonByIdsFromDB(request, missedIds, function (err, result) {

                        // write missed records back to cache
                        // NOTE: we cannot use missedIds here since the sequence of records in result are different
                        var ids = _.pluck(result, 'id');
                        var objs = _.map(result, function (obj) {
                            // remove all falsy properties to save cache space
                            // see http://stackoverflow.com/questions/14058193/remove-empty-properties-falsy-values-from-object-with-underscore-js
                            return _.pick(obj, _.identity);
                        });
                        Cache.mhmset(Cache.PersonStore, ids, objs);

                        // aggregate objs from cache and DB
                        var mergedObjs = cachedObjs.concat(objs);
                        var sortedObjs = _.sortBy(mergedObjs, function (person) {
                            return person.score * -1;  // Sort objs in DESC order by score
                        });

                        return callback(null, sortedObjs);
                    });
                }
            ], function (err, results) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                return reply(null, results);
            });
        }
    });


    // Get person id list in the cell. auth.
    // There is a (zip, cell) store in Cache to maintain the mapping relationship, which is to decouple zip and cell and make dynamic cell possible
    // Each cell has a sorted person id set read-through cache, and the key is the person score
    // In case of cache missing, DB will be queried and return a list of (personId, score) and update cache
    server.route({
        method: 'GET',
        path: options.basePath + '/person/nearby',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                query: {
                    gender: Joi.string().allow('M', 'F', 'X').required(),
                    zip: Joi.string().min(2).max(14).required(),
                    min: Joi.number().integer().default(0), // the minimum score, the search will include this value
                    max: Joi.number().positive().integer().default(Number.MAX_SAFE_INTEGER) // the maximum score, the search will include this value
                }
            }
        },
        handler: function (request, reply) {

            var r = request.query;
            var genderZip = r.gender + r.zip;

            Async.auto({
                genderCell: function (callback) {
                    var readonly = true;
                    internals.getPersonGenderCellFromZip(genderZip, readonly, function (err, result) {
                        if (err) {
                            return callback(err);
                        }

                        return callback(null, result);
                    });
                },
                cacheRecordCount: ['genderCell', function (callback, results) {
                    Cache.zcard(Cache.PeopleInCell, results.genderCell, function (err, result) {
                        if (err) {
                            console.error(err);
                            return callback(null, 0); // continue search in DB
                        }

                        return callback(null, result);
                    });
                }],
                readCache: ['cacheRecordCount', function (callback, results) {
                    if (results.cacheRecordCount === 0) {
                         return callback(null, null);
                    }

                    Cache.zrevrangebyscore(Cache.PeopleInCell, results.genderCell, r.max, r.min, Const.PERSON_PER_QUERY, function (err, result) {
                        if (err) {
                            console.error(err);
                            return callback(null, null); // continue search in DB
                        }

                        if (result.length === 0) {
                            return callback(null, null); // continue search in DB
                        }

                        return callback(Const.CACHE_HIT, result);
                    });
                }],
                readDB: ['readCache', function (callback, results) {

                    internals.searchPersonIdByCellFromDB(request, results.genderCell, function (err, result) {

                        if (result.length === 0) {
                            return callback(null, []);
                        }

                        var ids = _.pluck(result, 'id');
                        var scores = _.pluck(result, 'score');

                        // write back to cache
                        Cache.mzadd(Cache.PeopleInCell, results.genderCell, scores, ids);

                        return callback(null, ids);
                    });
                }]
            }, function (err, results) {

                if (err === Const.CACHE_HIT) {
                    return reply(null, results.readCache);
                }

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                return reply(null, results.readDB);
            });
        }
    });


    // get a person's own profile. auth.
    server.route({
        method: 'GET',
        path: options.basePath + '/person/me',
        config: {
            auth: {
                strategy: 'token'
            }
        },
        handler: function (request, reply) {

            var queryConfig = {
                name: 'person_read_by_id',
                text: selectAll +
                      'WHERE id = $1 AND deleted = false',
                values: [request.auth.credentials.id]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    console.error(err);
                    request.pg.kill = true;
                    return reply(err);
                }

                return reply(null, result.rows[0]);
            });
        }
    });


    // update a person's device information
    server.route({
        method: 'POST',
        path: options.basePath + '/person/device',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    service: Joi.number().min(1).max(3).required(),
                    device: Joi.string().max(100).required(),
                    badge: Joi.number().min(0).max(1000).default(0)
                }
            }
        },
        handler: function (request, reply) {

            var r = request.payload;
            var personId = request.auth.credentials.id;

            Async.auto({
                db: function (callback) {

                    var queryConfig = {
                        name: 'person_write_device_fields',
                        text: 'UPDATE person SET service = $1, device = $2, ut = $3 ' +
                              'WHERE id = $4 AND deleted = false ' +
                              'RETURNING id',
                        values: [r.service, r.device, _.now(), personId]
                    };

                    request.pg.client.query(queryConfig, function (err, result) {

                        if (err) {
                            request.pg.kill = true;
                            return callback(err);
                        }

                        if (result.rows.length === 0) {
                            return callback(Boom.badData(Const.PERSON_UPDATE_DEVICE_FAILED));
                        }

                        return callback(null);
                    });
                },
                cache: function (callback) {

                    Cache.hset(Cache.PersonStore, personId, 'badge', r.badge);
                    return callback(null);
                }
            }, function (err) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                return reply(null, r);
            });
        }
    });


    // update a person's profile. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/person/me',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    avatar: Joi.string().required(),
                    gender: Joi.string().allow('M', 'F', 'X').required(),
                    yob: Joi.number().min(1900).max(2010).required(),
                    lang: Joi.string().required()
                }
            }
        },
        handler: function (request, reply) {

            var r = request.payload;
            var personId = request.auth.credentials.id;

            Async.waterfall([

                function (callback) {

                    var queryConfig = {
                        name: 'person_write_profile',
                        text: 'UPDATE person SET avatar = $1, gender = $2, yob = $3, lang = $4, ut = $5 ' +
                              'WHERE id = $6 AND deleted = false ' +
                              'RETURNING id',
                        values: [r.avatar, r.gender, r.yob, r.lang, _.now(), personId]
                    };

                    request.pg.client.query(queryConfig, function (err, result) {

                        if (err) {
                            request.pg.kill = true;
                            return callback(err);
                        }

                        if (result.rows.length === 0) {
                            return callback(Boom.badRequest(Const.PERSON_UPDATE_PROFILE_FAILED));
                        }

                        r.id = personId;
                        delete r.lang;

                        Cache.hmset(Cache.PersonStore, personId, r);
                        return callback(null);
                    });
                }
            ], function (err) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                return reply(null, r);
            });
        }
    });


    // update an person's location. auth.
    server.route({
        method: 'POST',
        path: options.basePath + '/person/location',
        config: {
            auth: {
                strategy: 'token'
            },
            validate: {
                payload: {
                    zip: Joi.string().min(2).max(14).required(), // E.g., US94555
                    cell: Joi.string().min(3).max(12).required(), // E.g., MUS9
                    gender: Joi.string().allow('M', 'F', 'X').required() // used to generate gender cell
                }
            }
        },
        handler: function (request, reply) {

            var r = request.payload;
            var personId = request.auth.credentials.id;
            var genderZip = r.gender + r.zip; // MUS94555

            Async.auto({
                person: function (callback) {
                    internals.readPersonById(request, function (err, result) {

                        if (err) {
                            return callback(err);
                        }

                        return callback(null, result);
                    });
                },
                updateDB: ['person', function (callback, results) {
                    if (genderZip === results.person.zip) {
                        return callback(null, null);
                    }

                    var queryConfig = {
                        name: 'person_update_location',
                        text: 'UPDATE person SET zip = $1, ut = $2 ' +
                              'WHERE id = $3 AND deleted = false ' +
                              'RETURNING id',
                        values: [genderZip, _.now(), personId]
                    };

                    request.pg.client.query(queryConfig, function (err, result) {

                        if (err) {
                            request.pg.kill = true;
                            return callback(err);
                        }

                        if (result.rows.length === 0) {
                            return callback(Boom.badRequest(Const.PERSON_UPDATE_LOCATION_FAILED));
                        }

                        return callback(null, result);
                    });
                }],
                newCell: function (callback) {

                    var readonly = false;
                    internals.getPersonGenderCellFromZip(genderZip, readonly, function (err, result) {
                        if (err) {
                            return callback(err);
                        }

                        return callback(null, result);
                    });
                },
                updateCell: ['newCell', 'person', function (callback, results) {

                    var oldCell = r.cell;
                    var newCell = results.newCell;
                    if (oldCell === newCell) {
                        return callback(null, newCell);
                    }

                    Cache.zchangekey(Cache.PeopleInCell, oldCell, newCell, results.person.score, personId, function (err) {
                        if (err) {
                            return callback(err);
                        }
                        return callback(null, newCell);
                    });
                }]
            }, function (err, results) {

                if (err) {
                    console.error(err);
                    return reply(err);
                }

                var response = {
                    cell: results.updateCell
                };
                return reply(null, response);
            });
        }
    });

    next();
};


internals.searchPersonIdByCellFromDB = function (request, genderCell, callback) {

    var select = 'SELECT id, score FROM person ';
    var where = 'WHERE score >= $1 AND score <= $2 AND position($3 in zip) = 1 AND deleted = false ';
    var order = 'ORDER BY score DESC ';
    var limit = 'LIMIT 50';

    var queryValues = [request.query.min, request.query.max, genderCell];
    var queryConfig = {
        name: 'person_by_cell',
        text: select + where + order + limit,
        values: queryValues
    };

    request.pg.client.query(queryConfig, function (err, result) {

        if (err) {
            console.error(err);
            request.pg.kill = true;
            return callback(err);
        }

        return callback(null, result.rows);
    });
};


internals.searchPersonByIdsFromDB = function (request, personIds, callback) {

    var parameterList = Utils.parametersString(1, personIds.length);
    // Adding more conditions is to speed up the where-in search
    var where = 'WHERE deleted = false AND id in ' + parameterList;
    var order = 'ORDER BY score DESC ';
    var limit = 'LIMIT 50';

    var queryConfig = {
        // Warning: DO NOT give a name to this query since it has variable parameters
        text: selectAll + where + order + limit,
        values: personIds
    };

    request.pg.client.query(queryConfig, function (err, result) {

        if (err) {
            console.error(err);
            request.pg.kill = true;
            return callback(err);
        }

        return callback(null, result.rows);
    });
};


internals.readPersonById = function (request, reply) {

    var personId = request.auth.credentials.id;
    Async.auto({
        readCache: function (callback) {
            Cache.hgetall(Cache.PersonStore, personId, function (err, result) {
                if (err) {
                    console.error(err);
                    return callback(null);
                }

                return callback(Const.CACHE_HIT, result);
            });
        },
        readDB: ['readCache', function (callback) {
            var queryConfig = {
                name: 'person_read_by_id',
                text: selectAll + 'WHERE id = $1 AND deleted = false',
                values: [personId]
            };

            request.pg.client.query(queryConfig, function (err, result) {

                if (err) {
                    request.pg.kill = true;
                    return callback(err);
                }

                if (result.rows.length === 0) {
                    return callback(Boom.badRequest(Const.PERSON_NOT_FOUND));
                }

                return callback(null, result.rows[0]);
            });
        }]
    }, function (err, results) {

        if (err === Const.CACHE_HIT) {
            return reply(null, results.readCache);
        }

        if (err) {
            console.error(err);
            return reply(err);
        }

        return reply(null, results.readDB);
    });
};


internals.getPersonGenderCellFromZip = function (genderZip, readonly, reply) {

    var splitIndex = genderZip.length - 3;
    var zipPrefix = genderZip.substring(0, splitIndex);
    var zipSuffix = genderZip.substring(splitIndex);

    Async.auto({
        genderCell: function (callback) {

            Cache.hget(Cache.ZipGenderCellMap, zipPrefix, zipSuffix, function (err, result) {
                if (err) {
                    return callback(err);
                }

                var genderCell = result;
                if (!genderCell) {
                    genderCell = genderZip.substr(0, 3); // Use Gender + CountryCode as default genderCell, e.g., MUS
                }

                if (readonly) {
                    return callback(Const.CACHE_HIT, genderCell);
                }

                return callback(null, genderCell);
            });
        },
        personCount: ['genderCell', function (callback, results) {

            Cache.zcard(Cache.PeopleInCell, results.genderCell, function (err, result) {
                if (err) {
                    return callback(err);
                }

                return callback(null, result);
            });
        }],
        splitCell: ['personCount', function (callback, results) {

            var splitCell = results.genderCell;
            if (results.personCount > Const.PERSON_CELL_SPLIT_THRESHOLD) {

                splitCell = genderZip.substr(0, splitCell.length + 1); // Use one more letter as new genderCell
                Cache.hset(Cache.ZipGenderCellMap, zipPrefix, zipSuffix, splitCell);
            }
            return callback(null, splitCell);
        }]
    }, function (err, results) {

        if (err === Const.CACHE_HIT) {
            return reply(null, results.genderCell);
        }

        if (err) {
            console.error(err);
            return reply(err);
        }

        return reply(null, results.splitCell);
    });
};


exports.register.attributes = {
    name: 'person'
};
