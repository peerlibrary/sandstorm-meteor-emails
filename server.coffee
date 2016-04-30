__meteor_runtime_config__.SANDSTORM = true if process.env.SANDSTORM

MAIL_DIR = '/var/mail'

class SandstormEmailBase
  onNewEmail: (callback) ->
    throw new Error "Sandstorm not enabled."

  currentEmails: ->
    throw new Error "Sandstorm not enabled."

  deleteEmail: (path) ->
    throw new Error "Sandstorm not enabled."

  send: (options) ->
    throw new Error "Sandstorm not enabled."

# Exported symbol.
SandstormEmail = new SandstormEmailClass()

if __meteor_runtime_config__.SANDSTORM
  mkdirp = Npm.require 'mkdirp'
  fs = Npm.require 'fs'
  Future = Npm.require 'fibers/future'
  Capnp = Npm.require 'capnp'

  # Make sure mail spool maildir directories exist.
  mkdirp.sync "#{MAIL_DIR}/new",
    mode: 0700
  mkdirp.sync "#{MAIL_DIR}/cur",
    mode: 0700
  mkdirp.sync "#{MAIL_DIR}/tmp",
    mode: 0700

  maildir = new Maildir MAIL_DIR

  class SandstormEmailClass extends SandstormEmailBase
    constructor: ->
      @_onNewEmailCallbacks = []

    onNewEmail: (callback) ->
      @_onNewEmailCallbacks.push callback
      return

    currentEmails: ->
      emails = []
      future = new Future()

      # Copy files so that modifications in mean-time do not interfere.
      files = _.clone maildir.files
      errors = 0
      for path in files
        maildir.loadMessage path, (error, message) =>
          if error
            # We ignore errors, but we count them to know when to exit.
            errors++
            future.return emails if (emails.length + errors) is files.length
            return

          emails.push message

          future.return emails if (emails.length + errors) is files.length

      # This returns emails when loading all messages finishes.
      future.wait()

    # You can use message.path to get the path of the message.
    deleteEmail: (path) ->
      fs.unlinkSync "#{MAIL_DIR}/cur/#{path}"

    send: (options) ->
      throw new Error "Not implemented yet."

  # Exported symbol.
  SandstormEmail = new SandstormEmailClass()

  maildir.on 'newMessage', Meteor.bindEnvironment (message) ->
    callback message for callback in SandstormEmail._onNewEmailCallbacks
  ,
    'newMessage'

  Meteor.startup ->
    maildir.monitor()

  if Package['email']
    # If core e-mail package exists we adapt it to Sandstorm.
    Package['email'].Email.send = (options) ->
      SandstormEmail.send options

else
  # Exported symbol.
  SandstormEmail = new SandstormEmailBase()
