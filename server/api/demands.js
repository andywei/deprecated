var Async = require('async');
var Joi = require('joi');
var Hoek = require('hoek');
var AuthPlugin = require('../auth');


exports.register = function (server, options, next) {

    options = Hoek.applyToDefaults({ basePath: '' }, options);


    server.route({
        method: 'GET',
        path: options.basePath + '/demands',
        config: {
            auth: {
                strategy: 'simple',
                scope: 'account'
            },
            validate: {
                query: {
                    fields: Joi.string(),
                    sort: Joi.string().default('_id'),
                    limit: Joi.number().default(20),
                    page: Joi.number().default(1)
                }
            }
        },
        handler: function (request, reply) {

            var Demand = request.server.plugins['hapi-mongo-models'].Demand;
            var query = {};
            var fields = request.query.fields;
            var sort = request.query.sort;
            var limit = request.query.limit;
            var page = request.query.page;

            Demand.pagedFind(query, fields, sort, limit, page, function (err, results) {

                if (err) {
                    return reply(err);
                }

                reply(results);
            });
        }
    });


    server.route({
        method: 'GET',
        path: options.basePath + '/demands/{id}',
        config: {
            auth: {
                strategy: 'simple',
                scope: 'account'
            }
        },
        handler: function (request, reply) {

            var Demand = request.server.plugins['hapi-mongo-models'].Demand;

            Demand.findById(request.params.id, function (err, demand) {

                if (err) {
                    return reply(err);
                }

                if (!demand) {
                    return reply({ message: 'Document not found.' }).code(404);
                }

                reply(demand);
            });
        }
    });

//TODO
    server.route({
        method: 'GET',
        path: options.basePath + '/demands/my',
        config: {
            auth: {
                strategy: 'simple',
                scope: 'account'
            }
        },
        handler: function (request, reply) {

            var Demand = request.server.plugins['hapi-mongo-models'].Demand;
            var id = request.auth.credentials.roles.account._id.toString();
            var fields = Demand.fieldsAdapter('user name timeCreated');

            Demand.findById(id, fields, function (err, demand) {

                if (err) {
                    return reply(err);
                }

                if (!demand) {
                    return reply({ message: 'Document not found. That is strange.' }).code(404);
                }

                reply(demand);
            });
        }
    });

//TODO
    server.route({
        method: 'POST',
        path: options.basePath + '/demands',
        config: {
            auth: {
                strategy: 'simple',
                scope: 'account'
            },
            validate: {
                payload: {
                    name: Joi.string().required()
                }
            }
        },
        handler: function (request, reply) {

            var Demand = request.server.plugins['hapi-mongo-models'].Demand;
            var name = request.payload.name;

            Demand.create(name, function (err, demand) {

                if (err) {
                    return reply(err);
                }

                reply(demand);
            });
        }
    });


    server.route({
        method: 'PUT',
        path: options.basePath + '/demands/{id}',
        config: {
            auth: {
                strategy: 'simple',
                scope: 'account'
            },
            validate: {
                payload: {
                    name: Joi.object().keys({
                        first: Joi.string().required(),
                        middle: Joi.string().allow(''),
                        last: Joi.string().required()
                    }).required()
                }
            }
        },
        handler: function (request, reply) {

            var Demand = request.server.plugins['hapi-mongo-models'].Demand;
            var id = request.params.id;
            var update = {
                $set: {
                    name: request.payload.name
                }
            };

            Demand.findByIdAndUpdate(id, update, function (err, demand) {

                if (err) {
                    return reply(err);
                }

                reply(demand);
            });
        }
    });


    server.route({
        method: 'PUT',
        path: options.basePath + '/demands/my',
        config: {
            auth: {
                strategy: 'simple',
                scope: 'account'
            },
            validate: {
                payload: {
                    name: Joi.object().keys({
                        first: Joi.string().required(),
                        middle: Joi.string().allow(''),
                        last: Joi.string().required()
                    }).required()
                }
            }
        },
        handler: function (request, reply) {

            var Demand = request.server.plugins['hapi-mongo-models'].Demand;
            var id = request.auth.credentials.roles.account._id.toString();
            var update = {
                $set: {
                    name: request.payload.name
                }
            };
            var options = {
                fields: Demand.fieldsAdapter('user name timeCreated')
            };

            Demand.findByIdAndUpdate(id, update, options, function (err, demand) {

                if (err) {
                    return reply(err);
                }

                reply(demand);
            });
        }
    });


    server.route({
        method: 'PUT',
        path: options.basePath + '/demands/{id}/user',
        config: {
            auth: {
                strategy: 'simple',
                scope: 'account'
            },
            validate: {
                payload: {
                    username: Joi.string().lowercase().required()
                }
            },
            pre: [{
                assign: 'account',
                method: function (request, reply) {

                    var Demand = request.server.plugins['hapi-mongo-models'].Demand;

                    Demand.findById(request.params.id, function (err, demand) {

                        if (err) {
                            return reply(err);
                        }

                        if (!demand) {
                            return reply({ message: 'Document not found.' }).takeover().code(404);
                        }

                        reply(demand);
                    });
                }
            },{
                assign: 'user',
                method: function (request, reply) {

                    var User = request.server.plugins['hapi-mongo-models'].User;

                    User.findByUsername(request.payload.username, function (err, user) {

                        if (err) {
                            return reply(err);
                        }

                        if (!user) {
                            return reply({ message: 'User document not found.' }).takeover().code(404);
                        }

                        if (user.roles &&
                            user.roles.account &&
                            user.roles.account.id !== request.params.id) {

                            var response = {
                                message: 'User is already linked to another account. Unlink first.'
                            };

                            return reply(response).takeover().code(409);
                        }

                        reply(user);
                    });
                }
            },{
                assign: 'userCheck',
                method: function (request, reply) {

                    if (request.pre.account.user &&
                        request.pre.account.user.id !== request.pre.user._id.toString()) {

                        var response = {
                            message: 'Demand is already linked to another user. Unlink first.'
                        };

                        return reply(response).takeover().code(409);
                    }

                    reply(true);
                }
            }]
        },
        handler: function (request, reply) {

            Async.auto({
                account: function (done) {

                    var Demand = request.server.plugins['hapi-mongo-models'].Demand;
                    var id = request.params.id;
                    var update = {
                        $set: {
                            user: {
                                id: request.pre.user._id.toString(),
                                name: request.pre.user.username
                            }
                        }
                    };

                    Demand.findByIdAndUpdate(id, update, done);
                },
                user: function (done) {

                    var User = request.server.plugins['hapi-mongo-models'].User;
                    var id = request.pre.user._id;
                    var update = {
                        $set: {
                            'roles.account': {
                                id: request.pre.account._id.toString(),
                                name: request.pre.account.name.first + ' ' + request.pre.account.name.last
                            }
                        }
                    };

                    User.findByIdAndUpdate(id, update, done);
                }
            }, function (err, results) {

                if (err) {
                    return reply(err);
                }

                reply(results.account[0]);
            });
        }
    });


    server.route({
        method: 'DELETE',
        path: options.basePath + '/demands/{id}/user',
        config: {
            auth: {
                strategy: 'simple',
                scope: 'account'
            },
            pre: [{
                assign: 'account',
                method: function (request, reply) {

                    var Demand = request.server.plugins['hapi-mongo-models'].Demand;

                    Demand.findById(request.params.id, function (err, account) {

                        if (err) {
                            return reply(err);
                        }

                        if (!account) {
                            return reply({ message: 'Document not found.' }).takeover().code(404);
                        }

                        if (!account.user || !account.user.id) {
                            return reply(account).takeover();
                        }

                        reply(account);
                    });
                }
            },{
                assign: 'user',
                method: function (request, reply) {

                    var User = request.server.plugins['hapi-mongo-models'].User;

                    User.findById(request.pre.account.user.id, function (err, user) {

                        if (err) {
                            return reply(err);
                        }

                        if (!user) {
                            return reply({ message: 'User document not found.' }).takeover().code(404);
                        }

                        reply(user);
                    });
                }
            }]
        },
        handler: function (request, reply) {

            Async.auto({
                account: function (done) {

                    var Demand = request.server.plugins['hapi-mongo-models'].Demand;
                    var id = request.params.id;
                    var update = {
                        $unset: {
                            user: undefined
                        }
                    };

                    Demand.findByIdAndUpdate(id, update, done);
                },
                user: function (done) {

                    var User = request.server.plugins['hapi-mongo-models'].User;
                    var id = request.pre.user._id.toString();
                    var update = {
                        $unset: {
                            'roles.account': undefined
                        }
                    };

                    User.findByIdAndUpdate(id, update, done);
                }
            }, function (err, results) {

                if (err) {
                    return reply(err);
                }

                reply(results.account[0]);
            });
        }
    });


    server.route({
        method: 'POST',
        path: options.basePath + '/demands/{id}/notes',
        config: {
            auth: {
                strategy: 'simple',
                scope: 'account'
            },
            validate: {
                payload: {
                    data: Joi.string().required()
                }
            }
        },
        handler: function (request, reply) {

            var Demand = request.server.plugins['hapi-mongo-models'].Demand;
            var id = request.params.id;
            var update = {
                $push: {
                    notes: {
                        data: request.payload.data,
                        timeCreated: new Date(),
                        userCreated: {
                            id: request.auth.credentials.user._id.toString(),
                            name: request.auth.credentials.user.username
                        }
                    }
                }
            };

            Demand.findByIdAndUpdate(id, update, function (err, account) {

                if (err) {
                    return reply(err);
                }

                reply(account);
            });
        }
    });


    server.route({
        method: 'POST',
        path: options.basePath + '/demands/{id}/status',
        config: {
            auth: {
                strategy: 'simple',
                scope: 'account'
            },
            validate: {
                payload: {
                    status: Joi.string().required()
                }
            },
            pre: [{
                assign: 'status',
                method: function (request, reply) {

                    var Status = request.server.plugins['hapi-mongo-models'].Status;

                    Status.findById(request.payload.status, function (err, status) {

                        if (err) {
                            return reply(err);
                        }

                        reply(status);
                    });
                }
            }]
        },
        handler: function (request, reply) {

            var Demand = request.server.plugins['hapi-mongo-models'].Demand;
            var id = request.params.id;
            var newStatus = {
                id: request.pre.status._id.toString(),
                name: request.pre.status.name,
                timeCreated: new Date(),
                userCreated: {
                    id: request.auth.credentials.user._id.toString(),
                    name: request.auth.credentials.user.username
                }
            };
            var update = {
                $set: {
                    'status.current': newStatus
                },
                $push: {
                    'status.log': newStatus
                }
            };

            Demand.findByIdAndUpdate(id, update, function (err, demand) {

                if (err) {
                    return reply(err);
                }

                reply(demand);
            });
        }
    });


    server.route({
        method: 'DELETE',
        path: options.basePath + '/demands/{id}',
        config: {
            auth: {
                strategy: 'simple',
                scope: 'account'
            },
            pre: [
                AuthPlugin.preware.ensureAdminGroup('root')
            ]
        },
        handler: function (request, reply) {

            var Demand = request.server.plugins['hapi-mongo-models'].Demand;

            Demand.findByIdAndRemove(request.params.id, function (err, count) {

                if (err) {
                    return reply(err);
                }

                if (count === 0) {
                    return reply({ message: 'Document not found.' }).code(404);
                }

                reply({ message: 'Success.' });
            });
        }
    });


    next();
};


exports.register.attributes = {
    name: 'demands'
};
