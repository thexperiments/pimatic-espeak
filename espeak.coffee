# #Play Plugin

# This is an plugin to use the espeak tts in pimatic

# ##The plugin code

# Your plugin must export a single function, that takes one argument and returns a instance of
# your plugin class. The parameter is an envirement object containing all pimatic related functions
# and classes. See the [startup.coffee](http://sweetpi.de/pimatic/docs/startup.html) for details.
module.exports = (env) ->

  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  util = env.require 'util'
  M = env.matcher
  child_p = require 'child_process'

  # ###espeak class
  class espeakPlugin extends env.plugins.Plugin

    # ####init()
    init: (app, @framework, config) =>
      
      language = config.language
      env.logger.debug "espeak: language = #{language}"
      
      @framework.ruleManager.addActionProvider(new espeakActionProvider @framework, config)
  
  # Create a instance of my plugin
  plugin = new espeakPlugin()

  class espeakActionProvider extends env.actions.ActionProvider
  
    constructor: (@framework, @config) ->
      return

    parseAction: (input, context) =>
      #get language from config to pass it to action handler
      language = @config.language

      # Helper to convert 'some text' to [ '"some text"' ]
      strToTokens = (str) => ["\"#{str}\""]

      textTokens = strToTokens ""

      setText = (m, tokens) => textTokens = tokens

      m = M(input, context)
        .match(['say ']).matchStringWithVars(setText)

      if m.hadMatch()
        match = m.getFullMatch()

        assert Array.isArray(textTokens)

        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new espeakActionHandler(
            @framework, textTokens, language
          )
        }
            

  class espeakActionHandler extends env.actions.ActionHandler 

    constructor: (@framework, @textTokens, @language) ->

    executeAction: (simulate, context) ->
      Promise.all( [
        @framework.variableManager.evaluateStringExpression(@textTokens)
      ]).then( ([text]) =>
        if simulate
          # just return a promise fulfilled with a description about what we would do.
          return __("would say \"%s\"", text)
        else
          #get language setting
          language = @language

          return new Promise((resolve, reject) ->

            #spawn aplay with default audio device
            aplay_process = child_p.spawn "aplay"
            #spawn espeak
            espeak_process = child_p.spawn("espeak", ["-v#{language}"
              "--stdout"
              text])
            #connect them
            espeak_process.stdout.on "data", (data) ->
              aplay_process.stdin.write data
            
            #redirect errors
            espeak_process.stderr.on "data", (data) ->
              process.stderr.write data
            
            aplay_process.stderr.on "data", (data) ->
              process.stderr.write data
            
            #clean up after speaking
            espeak_process.on "close", (code) ->
              if code != 0
                aplay_process.stdin.end()
                reject env.logger.error "espeak exited with code #{code}"
              #close stdin of aplay after espeak is done
              aplay_process.stdin.end()
              resolve __("said: \"%s\"", text)
          )
      )

  module.exports.espeakActionHandler = espeakActionHandler

  # and return it to the framework.
  return plugin   
