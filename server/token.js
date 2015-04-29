var Async = require('async');
var Boom = require('boom');
var Hoek = require('hoek');
var c = require('./constants');
var rand = require('rand-token');

var bearerTokenCache = null;
var deviceTokenCache = null;

exports.attach = function (server) {

    Hoek.assert(!bearerTokenCache, 'Bearer token cache should only be set once.');
    bearerTokenCache = server.cache({
        segment: 'bearer',
        expiresIn: 60 * 60 * 1000
    });

    Hoek.assert(!deviceTokenCache, 'Device token cache should only be set once.');
    deviceTokenCache = server.cache({
        segment: 'device',
        expiresIn: 2 * 365 * 24 * 60 * 60 * 1000
    });
};


exports.detach = function () {

    bearerTokenCache = null;
    deviceTokenCache = null;
};


// tokenObj = {token:$token, badge: $n, service:$s} $s = 1 - apn, 2 - gcm, 3 - mpn
exports.getDeviceTokenObject = function (userId, callback) {

    Hoek.assert(deviceTokenCache, 'Device token cache should be set beforehand.');

    userId = userId.toString();
    deviceTokenCache.get(userId, function (err, tokenObj) {

        if (err) {
            return callback(Boom.serverTimeout(err));
        }

        if (!tokenObj) {
            return callback(Boom.notFound(c.DEVICE_TOKEN_NOT_FOUND));
        }

        callback(null, tokenObj);
    });
};


exports.setDeviceTokenObject = function (userId, tokenObj, callback) {

    Hoek.assert(deviceTokenCache, 'Device token cache should be set beforehand.');

    userId = userId.toString();
    deviceTokenCache.set(userId, tokenObj, 0, function (err) {

        if (err) {
            return callback(err);
        }

        callback(null, userId);
    });
};


// Generate a 20 character alpha-numeric token and store it in bearerTokenCache
exports.generateBearerToken = function (userId, userName, callback) {

    Hoek.assert(bearerTokenCache, 'Bearer token cache should be set beforehand.');

    userId = userId.toString();
    userName = userName.toString();

    Async.auto({
        existedToken: function (next) {

            bearerTokenCache.get(userId, function (err, value) {

                if (err) {
                    return next(err);
                }

                if (value) { // there is a token already, so fake a err here to stop generating new token
                    return next('token_found', value);
                }

                next(null, null);
            });
        },
        generateToken: function (next) {

            var token = rand.generate(c.TOKEN_LENGTH);
            next(null, token);
        },
        cacheToken: ['existedToken', 'generateToken', function (next, results) {

            var userInfo = {
                id: userId,
                username: userName
            };

            bearerTokenCache.set(results.generateToken, userInfo, 0, function (err) {

                if (err) {
                    return next(err);
                }

                next(null);
            });
        }],
        cacheUserId: ['existedToken', 'generateToken', function (next, results) {

            bearerTokenCache.set(userId, results.generateToken, 0, function (err) {

                if (err) {
                    return next(err);
                }

                next(null);
            });
        }]
    }, function (err, results) {

        if (err === 'token_found') {
            return callback(null, results.existedToken); // just return the existedToken
        }

        if (err) {
            console.error(err);
            return callback(err);
        }

        callback(null, results.generateToken);
    });
};


exports.destroyBearerToken = function (token, callback) {

    Hoek.assert(bearerTokenCache, 'Bearer token cache should be set beforehand.');
    bearerTokenCache.drop(token, function (err) {

        if (err) {
            return callback(err);
        }

        callback(null, true);
    });
};


exports.validateBearerToken = function (token, callback) {

    Hoek.assert(bearerTokenCache, 'Bearer token cache should be set beforehand.');
    bearerTokenCache.get(token, function (err, value) {

        if (err) {
            return callback(err);
        }

        if (!value) {
            return callback(new Error(c.TOKEN_INVALID));
        }

        callback(null, value);
    });
};

