Package.describe({
  name: 'peerlibrary:sandstorm-meteor-emails',
  summary: "E-mail support for Sandstorm",
  version: '0.1.0',
  git: 'https://github.com/peerlibrary/sandstorm-meteor-emails.git'
});

Npm.depends({
  'mkdirp': '0.5.1',
  'maildir': '0.5.0'
});

Package.onUse(function (api) {
  api.versionsFrom('METEOR@1.0.3.1');

  // Core dependencies.
  api.use([
    'coffeescript',
    'underscore',
    'logging'
  ], 'server');

  api.use([
    'email'
  ], {weak: true});

  api.export('SandstormEmail', 'server');

  api.addFiles([
    'server.coffee'
  ], 'server');
});
