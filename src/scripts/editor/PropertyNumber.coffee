define (require) ->
  $ = require 'jquery'
  Signals = require 'Signal'
  _ = require 'lodash'
  d3 = require 'd3'
  Utils = require 'cs!core/Utils'
  PropertyBase = require 'cs!editor/PropertyBase'
  DraggableNumber = require 'draggablenumber'

  Mustache = require 'Mustache'
  tpl_property = require 'text!templates/propertyNumber.tpl.html'

  class PropertyNumber extends PropertyBase
    # @instance_property: The current property on the data object.
    # @lineData: The line data object.
    constructor: (@instance_property, @lineData, @editor, @key_val = false) ->
      super
      @$input = @$el.find('input')

    getInputVal: () =>
      parseFloat(@$el.find('input').val())

    render: () =>
      super
      # By default assign the property default value
      val = @getCurrentVal()

      data =
        id: @instance_property.name # "circleRadius" instead of "circle radius"
        label: @instance_property.label || @instance_property.name
        val: val

      view = Mustache.render(tpl_property, data)
      @$el = $(view)
      @$el.find('.property__key').click(@onKeyClick)

      $input = @$el.find('input')
      onInputChange = (e) =>
        current_value = @getInputVal()
        currentTime = @timer.getCurrentTime() / 1000
        # if we selected a key simply get the time from it.
        if @key_val then currentTime = @key_val.time

        if @instance_property.keys && @instance_property.keys.length
          # Add a new key if there is no other key at same time
          current_key = _.find(@instance_property.keys, (key) => key.time == currentTime)

          if current_key
            # if there is a key update it
            current_key.val = current_value
          else
            # add a new key
            @addKey(current_value)
        else
          # There is no keys, simply update the property value (for data saving)
          @instance_property.val = current_value
          # Also directly set the lineData value.
          @lineData.values[@instance_property.name] = current_value

          # Simply update the custom object with new values.
          if @lineData.object
            currentTime = @timer.getCurrentTime() / 1000
            # Set the property on the instance object.
            @lineData.object.update(currentTime - @lineData.start)

        # Something changed, make the lineData dirty to rebuild things. d
        @lineData._isDirty = true

      onChangeEnd = (new_val) =>
        @editor.undoManager.addState()

      draggable = new DraggableNumber($input.get(0), {
        changeCallback: onInputChange,
        endCallback: onChangeEnd
      })
      $input.data('draggable', draggable)
      $input.change(onInputChange)

    update: () =>
      super
      val = @getCurrentVal()
      draggable = @$input.data('draggable')

      if draggable
        draggable.set(val.toFixed(3))
      else
        @$input.val(val.toFixed(3))
