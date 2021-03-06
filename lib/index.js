// Generated by CoffeeScript 1.10.0
(function() {
  var CrowdBackend, CrowdClient, Q, getUidFromFilter, ldapjs,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Q = require('q');

  ldapjs = require('ldapjs');

  CrowdClient = require('atlassian-crowd-client');

  getUidFromFilter = function(filter, attribute) {
    var filters, index, uid;
    if (filter.type === 'equal') {
      if (filter.attribute === attribute) {
        return filter.value;
      } else {
        return null;
      }
    } else if (filter.type === 'and') {
      filters = filter.filters;
      uid = null;
      index = 0;
      while (uid === null && index < filters.length) {
        uid = getUidFromFilter(filters[index++], attribute);
      }
      return uid;
    } else {
      return null;
    }
  };

  CrowdBackend = (function() {
    function CrowdBackend(params1) {
      this.params = params1;
      this.search = bind(this.search, this);
      this.bind = bind(this.bind, this);
      this.authorizeThen = bind(this.authorizeThen, this);
      this.authorize = bind(this.authorize, this);
      this.createSearchEntry = bind(this.createSearchEntry, this);
      this.crowd = new CrowdClient({
        baseUrl: this.params.crowd.url,
        application: {
          name: this.params.crowd.applicationName,
          password: this.params.crowd.applicationPassword
        }
      });
      this.bindDn = ldapjs.parseDN(this.params.ldap.bindDn + ',' + this.params.ldap.dnSuffix);
      this.searchBase = ldapjs.parseDN(this.params.ldap.searchBase + ',' + this.params.ldap.dnSuffix);
    }

    CrowdBackend.prototype.createSearchEntry = function(user) {
      var attributes;
      attributes = {};
      attributes[this.params.ldap.uid] = user.username;
      attributes.givenName = user.firstname;
      attributes.sn = user.lastname;
      attributes.displayName = user.displayname;
      attributes.mail = user.email;
      attributes.objectclass = 'person';
      return {
        dn: this.params.ldap.uid + '=' + user.username + ',' + this.searchBase,
        attributes: attributes
      };
    };

    CrowdBackend.prototype.authorize = function(req, red, next) {
      if (!req.connection.ldap.bindDN.equals(this.bindDn)) {
        return next(new ldapjs.InsufficientAccessRightsError);
      }
      return next();
    };

    CrowdBackend.prototype.authorizeThen = function(next) {
      return [this.authorize, next];
    };

    CrowdBackend.prototype.bind = function() {
      return (function(_this) {
        return function(req, res, next) {
          var deferred, first, promised, rdns, uid, username;
          promised = false;
          deferred = Q.defer();
          deferred.promise.then(function() {
            res.end();
            return next();
          })["catch"](function(error) {
            return next(new ldapjs.InvalidCredentialsError());
          }).done();
          if (req.dn.equals(_this.bindDn)) {
            if (req.credentials !== _this.params.ldap.bindPassword) {
              return next(new ldapjs.InvalidCredentialsError());
            }
          } else if (req.dn.childOf(_this.searchBase)) {
            rdns = req.dn.rdns;
            if (rdns.length !== 3) {
              return next(new ldapjs.InvalidCredentialsError());
            }
            first = rdns[0].attrs;
            uid = _this.params.ldap.uid;
            if (!first[uid]) {
              return next(new ldapjs.InvalidCredentialsError());
            }
            username = first[uid].value;
            promised = true;
            Q(_this.crowd.authentication.authenticate(username, req.credentials)).then(function() {
              return deferred.resolve();
            })["catch"](function(error) {
              return deferred.reject(error);
            }).done();
          } else {
            return next(new ldapjs.InvalidCredentialsError());
          }
          if (!promised) {
            return deferred.resolve();
          }
        };
      })(this);
    };

    CrowdBackend.prototype.search = function() {
      return this.authorizeThen((function(_this) {
        return function(req, res, next) {
          var deferred, first, promised, rdns, uid, username;
          promised = false;
          deferred = Q.defer();
          deferred.promise.then(function() {
            res.end();
            return next();
          }).done();
          if (req.dn.equals(_this.searchBase)) {
            if (req.scope = 'sub') {
              uid = getUidFromFilter(req.filter, _this.params.ldap.uid);
              if (uid !== null) {
                promised = true;
                Q(_this.crowd.user.get(uid)).then(function(user) {
                  var entry;
                  if (user.active) {
                    entry = _this.createSearchEntry(user);
                    if (req.filter.matches(entry.attributes)) {
                      res.send(entry);
                    }
                  }
                  return deferred.resolve();
                })["catch"](function() {
                  return deferred.resolve();
                }).done();
              }
            }
          } else if (req.dn.childOf(_this.searchBase)) {
            rdns = req.dn.rdns;
            if (rdns.length === 3) {
              first = rdns[0].attrs;
              uid = _this.params.ldap.uid;
              if (first[uid]) {
                username = first[uid].value;
                if (req.scope = 'base') {
                  promised = true;
                  Q(_this.crowd.user.get(username)).then(function(user) {
                    if (user.active) {
                      res.send(_this.createSearchEntry(user));
                    }
                    return deferred.resolve();
                  })["catch"](function() {
                    return deferred.resolve();
                  }).done();
                }
              }
            }
          } else {
            return next(new ldapjs.NoSuchObjectError());
          }
          if (!promised) {
            return deferred.resolve();
          }
        };
      })(this));
    };

    return CrowdBackend;

  })();

  module.exports.createBackend = function(params) {
    return new CrowdBackend(params);
  };

}).call(this);
