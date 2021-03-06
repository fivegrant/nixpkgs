import ./make-test-python.nix ({ pkgs, ... }:

let
  configDir = "/var/lib/foobar";
  mqttPassword = "secret";
in {
  name = "home-assistant";
  meta = with pkgs.stdenv.lib; {
    maintainers = with maintainers; [ dotlambda ];
  };

  nodes.hass = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [ mosquitto ];
    services.home-assistant = {
      inherit configDir;
      enable = true;
      config = {
        homeassistant = {
          name = "Home";
          time_zone = "UTC";
          latitude = "0.0";
          longitude = "0.0";
          elevation = 0;
        };
        frontend = {};
        # uses embedded mqtt broker
        mqtt.password = mqttPassword;
        binary_sensor = [{
          platform = "mqtt";
          state_topic = "home-assistant/test";
          payload_on = "let_there_be_light";
          payload_off = "off";
        }];
        logger = {
          default = "info";
          logs."homeassistant.components.mqtt" = "debug";
        };
      };
      lovelaceConfig = {
        title = "My Awesome Home";
        views = [{
          title = "Example";
          cards = [{
            type = "markdown";
            title = "Lovelace";
            content = "Welcome to your **Lovelace UI**.";
          }];
        }];
      };
      lovelaceConfigWritable = true;
    };
  };

  testScript = ''
    start_all()
    hass.wait_for_unit("home-assistant.service")
    with subtest("Check that YAML configuration file is in place"):
        hass.succeed("test -L ${configDir}/configuration.yaml")
    with subtest("lovelace config is copied because lovelaceConfigWritable = true"):
        hass.succeed("test -f ${configDir}/ui-lovelace.yaml")
    with subtest("Check that Home Assistant's web interface and API can be reached"):
        hass.wait_for_open_port(8123)
        hass.succeed("curl --fail http://localhost:8123/lovelace")
    with subtest("Toggle a binary sensor using MQTT"):
        # wait for broker to become available
        hass.wait_until_succeeds(
            "mosquitto_sub -V mqttv311 -t home-assistant/test -u homeassistant -P '${mqttPassword}' -W 1 -t '*'"
        )
        hass.succeed(
            "mosquitto_pub -V mqttv311 -t home-assistant/test -u homeassistant -P '${mqttPassword}' -m let_there_be_light"
        )
    with subtest("Print log to ease debugging"):
        output_log = hass.succeed("cat ${configDir}/home-assistant.log")
        print("\n### home-assistant.log ###\n")
        print(output_log + "\n")

    with subtest("Check that no errors were logged"):
        assert "ERROR" not in output_log

    # example line: 2020-06-20 10:01:32 DEBUG (MainThread) [homeassistant.components.mqtt] Received message on home-assistant/test: b'let_there_be_light'
    with subtest("Check we received the mosquitto message"):
        assert "let_there_be_light" in output_log
  '';
})
