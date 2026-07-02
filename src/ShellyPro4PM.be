class ShellyPro4PM
  var relayCount

  def init()
    import string
    import haspmota
    var status = tasmota.cmd("status", true)['Status']
    var deviceName = status['DeviceName']
    var relayNames = status['FriendlyName']
    self.relayCount = relayNames.size()-1

    haspmota.start(tasmota.wd + 'shelly-pro-4pm.jsonl')

    haspmota.parse('{"id":1,"obj":"flex","flex_flow":1,"pad_row":1,"flex_main_place":2}')
    haspmota.parse('{"id":2,"parentid":1,"obj":"flex","h":18,"flex_flow":0,"flex_track_place":2,"pad_column":2,"text_color":"#ffffff","bg_color":"#0000FF","bg_opa":255}')
    haspmota.parse(f'{{"id":3,"parentid":2,"obj":"label","text":"{deviceName}","flex_grow":1,"long_mode":4}}')
    haspmota.parse('{"id":4,"parentid":2,"obj":"label","text":"--"}')
    haspmota.parse('{"id":5,"parentid":2,"obj":"label","text":":"}')
    haspmota.parse('{"id":6,"parentid":2,"obj":"label","text":"--"}')
    haspmota.parse('{"id":9,"parentid":2,"obj":"lv_wifi_arcs","w":20,"h":16,"line_color":"#ffffff"}')

    for relay: 0..self.relayCount
      var line = (relay+1)*10
      var displayLine = (relay == self.relayCount)
      var name = relayNames[relay]
      var useDefaultName = (name == "" || string.find(name,"Tasmota") == 0)
      var relayName = (useDefaultName ? (displayLine ? "Display" : f"CH {relay+1}") : name)
      var relayState = tasmota.get_power(relay)
      haspmota.parse(f'{{"id":{line},"parentid":1,"obj":"flex","flex_grow":1,"flex_flow":0,"flex_track_place":2,"pad_right":1,"text_color":"#000000","bg_color":"#FFFFFF","bg_opa":255}}')
      haspmota.parse(f'{{"id":{line+1},"parentid":{line},"obj":"label","text":"{relayName}","flex_grow":1,"long_mode":4}}')
      haspmota.parse(f'{{"id":{line+2},"parentid":{line},"obj":"switch","h":16,"w":30,"toggle":{relayState}}')
      tasmota.add_rule(f'hasp#p1b{line+2}#event=changed', / event -> self.update_relay(relay))
      tasmota.add_rule(f'POWER{relay+1}#state', / value -> self.update_switch(relay, value))
    end

    tasmota.add_driver(self)
  end

  def unload()
    tasmota.remove_driver(self)
    global.p1b9.get_obj().before_del()
    global.p1.delete()
  end

  def del_element(b)
    var element = compile(f'return p1b{b}')()
    if element
      element.delete()
    end
  end

  def get_switch(relay)
    return compile(f'return p1b{relay+1}2')()
  end

  def update_relay(relay)
    var switch = self.get_switch(relay)
    if switch
      tasmota.set_power(relay,switch.toggle)
    end
  end

  def update_switch(relay, powered)
    var switch = self.get_switch(relay)
    if switch
      switch.toggle = powered
    end
  end

  def every_second()
    var rtc = tasmota.rtc()['local']
    var now = tasmota.time_dump(rtc)
    if now['year'] != 1970
      var hour = now['hour']
      var min = now['min']
      var sec = now['sec']
      global.p1b4.text = f'{hour:02d}'
      if sec % 2
        global.p1b5.text_opa = lv.OPA_TRANSP
      else
        global.p1b5.text_opa = lv.OPA_COVER
      end
      global.p1b6.text = f'{min:02d}'
    end
  end

end

return ShellyPro4PM()