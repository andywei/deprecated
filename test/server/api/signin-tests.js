var AuthPlugin = require('../../../server/authenticate');
var Cache = require('../../../server/cache');
var Code = require('code');
var Config = require('../../../config');
var Hapi = require('hapi');
var HapiAuthBasic = require('hapi-auth-basic');
var HapiAuthToken = require('hapi-auth-bearer-token');
var Lab = require('lab');
var SignInPlugin = require('../../../server/api/signin');
var c = require('../../../server/constants');


var lab = exports.lab = Lab.script();

var request, server;

var jack = {
    id: 1,
    name: 'jack'
};


lab.experiment('SignIn: ', function () {

    lab.before(function (done) {

        var plugins = [HapiAuthBasic, HapiAuthToken, AuthPlugin, SignInPlugin];
        server = new Hapi.Server();
        server.connection({ port: Config.get('/port/api') });
        server.register(plugins, function (err) {

            if (err) {
                return done(err);
            }

            server.start(function () {

                Cache.start(function (error) {
                    if (error) {
                        return done(error);
                    }
                    return done();
                });
            });
        });
    });


    lab.after(function (done) {

        server.stop(function () {

            Cache.stop();
            return done();
        });
    });


    lab.test('assign token successfully', function (done) {

        request = {
            method: 'GET',
            url: '/signin',
            credentials: jack
        };

        server.inject(request, function (response) {

            Code.expect(response.statusCode).to.equal(200);
            Code.expect(response.result.token).to.exist().and.to.have.length(c.TOKEN_LENGTH);
            return done();
        });
    });
});
