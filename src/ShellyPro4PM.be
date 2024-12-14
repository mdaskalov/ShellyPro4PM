  import string
  import math

  class ShellyPro4PM

    var deviceName
    var relayNames
    var relayCount
    var relayLabels
    var header
    var clock

    def init()
      var status = tasmota.cmd("status", true)['Status']
      self.deviceName = status['DeviceName']
      self.relayNames = status['FriendlyName']
      self.relayCount = self.relayNames.size()
      self.relayLabels = []

      lv.start()
      var scr = lv.scr_act()
      self.header = lv.label(lv.scr_act())
      self.set_header(self.deviceName, lv.COLOR_WHITE, lv.COLOR_NAVY)
      self.set_relay_labels(lv.COLOR_BLACK, lv.COLOR_WHITE, lv.COLOR_GRAY, lv.COLOR_NAVY)
      for relay: 0..self.relayNames.size()-1
        self.update_relay(relay, tasmota.get_power(relay))
      end
      self.add_relay_rules();
      tasmota.add_driver(self)
    end

    def deinit()
      self.del()
    end

    def del()
      self.remove_relay_rules()
      tasmota.remove_driver(self)
      if self.header
        self.header.del()
        self.header = nil
      end
      if self.clock
        self.clock.del()
        self.clock = nil
      end
      if self.relayLabels
        for label : self.relayLabels
          label.del()
        end
        self.relayLabels = nil
      end
    end

    def add_relay_rules()
      for relay: 0..self.relayCount
        tasmota.add_rule(f"POWER{relay+1}#state", def (value) self.update_relay(relay, value) end )
      end
    end

    def remove_relay_rules()
      for relay: 0..self.relayCount
        tasmota.remove_rule(f"POWER{relay+1}#state")
      end
    end

    def line_label(line, text, fg_color, bg_color)
      var label = lv.label(lv.scr_act())
      label.set_y(21*line)
      label.set_size(lv.get_hor_res(), 20)
      label.set_style_pad_left(2,lv.PART_MAIN | lv.STATE_DEFAULT)
      label.set_style_pad_top(2,lv.PART_MAIN | lv.STATE_DEFAULT)
      label.set_style_bg_color(lv.color(bg_color), lv.PART_MAIN | lv.STATE_DEFAULT)
      label.set_style_bg_opa(lv.OPA_COVER, lv.PART_MAIN | lv.STATE_DEFAULT)
      label.set_style_text_color(lv.color(fg_color), lv.PART_MAIN | lv.STATE_DEFAULT)
      label.set_text(text)
      return label
    end

    def set_header(device, fg_color, bg_color)
      self.header.set_text(device)
      self.header.set_size(lv.get_hor_res(), 21)
      self.header.set_style_pad_left(2,lv.PART_MAIN | lv.STATE_DEFAULT)
      self.header.set_style_pad_top(4,lv.PART_MAIN | lv.STATE_DEFAULT)
      self.header.set_style_bg_color(lv.color(bg_color), lv.PART_MAIN | lv.STATE_DEFAULT)
      self.header.set_style_bg_opa(lv.OPA_COVER, lv.PART_MAIN | lv.STATE_DEFAULT)
      self.header.set_style_text_color(lv.color(fg_color), lv.PART_MAIN | lv.STATE_DEFAULT)
      self.header.update_layout();

      self.clock = lv.label(self.header)
      self.clock.set_text("--:--")
      var font = lv.seg7_font(14)
      if font self.clock.set_style_text_font(font, lv.PART_MAIN | lv.STATE_DEFAULT) end
      self.clock.set_style_bg_color(lv.color(bg_color), lv.PART_MAIN | lv.STATE_DEFAULT)
      self.clock.set_style_bg_opa(lv.OPA_COVER, lv.PART_MAIN | lv.STATE_DEFAULT)
      self.clock.set_style_text_color(lv.color(fg_color), lv.PART_MAIN | lv.STATE_DEFAULT)
      self.clock.set_style_text_opa(lv.OPA_90, lv.PART_MAIN | lv.STATE_DEFAULT)
      self.clock.update_layout();
      self.clock.align_to(self.header, lv.ALIGN_RIGHT_MID, -5, -1)

      var wifi = lv_wifi_bars_icon(self.header)
      wifi.set_size(15,13)
      wifi.set_style_bg_color(lv.color(bg_color), lv.PART_MAIN | lv.STATE_DEFAULT)
      wifi.set_style_bg_opa(lv.OPA_COVER, lv.PART_MAIN | lv.STATE_DEFAULT)
      wifi.set_style_line_color(lv.color(fg_color), lv.PART_MAIN | lv.STATE_DEFAULT)
      wifi.update_layout();
      wifi.align_to(self.clock, lv.ALIGN_OUT_LEFT_MID, -2, 0)

      self.header.set_style_pad_right(self.clock.get_width() + wifi.get_width() + 8, lv.PART_MAIN | lv.STATE_DEFAULT)
    end

    def set_relay_labels(fg_color, bg_color, bg_color_off, bg_color_on)
      var line = 1
      for name : self.relayNames
        var displayLine = (line == self.relayCount)
        var useDefaultName = (name == "" || string.find(name,"Tasmota") == 0)
        var relayName = (useDefaultName ? (displayLine ? "Display" : f"CH {line}") : name)
        var label = self.line_label(line, relayName, fg_color, bg_color)
        var switch = lv.switch(label)
        switch.set_size(27,15)
        switch.set_style_bg_color(lv.color(bg_color_off), lv.PART_MAIN | lv.STATE_DEFAULT)
        switch.set_style_bg_color(lv.color(bg_color_on), lv.PART_INDICATOR | lv.STATE_CHECKED)
        switch.align_to(label, lv.ALIGN_RIGHT_MID, -5, -1)
        self.relayLabels.push(label)
        line += 1
      end
    end

    def update_time(hour, min, sec)
      import string
      var txt = string.format("%02d%s%02d",hour,sec % 2 ? ":" : " ",min)
      if self.clock
        self.clock.set_text(txt)
      end
    end

    def update_relay(relay, powered)
      var label = self.relayLabels[relay]
      if label
        var switch = label.get_child(0)
        if switch
          if powered
            switch.add_state(lv.STATE_CHECKED)
          else
            switch.clear_state(lv.STATE_CHECKED)
          end
        end
      end
    end

    def every_second()
      var rtc = tasmota.rtc()['local']
      var now = tasmota.time_dump(rtc)
      if now['year'] != 1970
        self.update_time(now['hour'], now['min'], now['sec'])
      end
    end

  end

  return ShellyPro4PM
