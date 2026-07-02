# rm -f ShellyPro4PM.tapp; zip -j -0 ShellyPro4PM.tapp src/*.be src/*.jsonl
do                          # embed in `do` so we don't add anything to global namespace
  import introspect
  var shelly = introspect.module('ShellyPro4PM', true)     # load module but don't cache
  tasmota.add_extension(shelly)
end