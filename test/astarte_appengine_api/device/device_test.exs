defmodule Astarte.AppEngine.API.DeviceTest do
  use ExUnit.Case
  alias Astarte.AppEngine.API.Device
  alias Astarte.AppEngine.API.Device.DeviceStatus
  alias Astarte.AppEngine.API.Device.DeviceNotFoundError
  alias Astarte.AppEngine.API.Device.DevicesListingNotAllowedError
  alias Astarte.AppEngine.API.Device.EndpointNotFoundError
  alias Astarte.AppEngine.API.Device.InterfaceNotFoundError
  alias Astarte.AppEngine.API.Device.InterfaceValues
  alias Astarte.AppEngine.API.Device.PathNotFoundError

  setup do
    {:ok, _client} = Astarte.RealmManagement.DatabaseTestHelper.create_test_keyspace()

    on_exit fn ->
      Astarte.RealmManagement.DatabaseTestHelper.destroy_local_test_keyspace()
    end
  end

  test "list_interfaces!/2 returns all interfaces" do
    assert Device.list_interfaces!("autotestrealm", "f0VMRgIBAQAAAAAAAAAAAAIAPgABAAAAsCVAAAAAAABAAAAAAAAAADDEAAAAAAAAAAAAAEAAOAAJ") == ["com.example.TestObject", "com.test.LCDMonitor", "com.test.SimpleStreamTest"]
  end

  test "get_interface_values! returns interfaces values on individual property interface" do
    expected_reply = %{"time" => %{"from" => 8, "to" => 20}, "lcdCommand" => "SWITCH_ON", "weekSchedule" => %{"2" => %{"start" => 12, "stop" => 15}, "3" => %{"start" => 15, "stop" => 16}, "4" => %{"start" => 16, "stop" => 18}}}
    assert unpack_interface_values(Device.get_interface_values!("autotestrealm", "f0VMRgIBAQAAAAAAAAAAAAIAPgABAAAAsCVAAAAAAABAAAAAAAAAADDEAAAAAAAAAAAAAEAAOAAJ", "com.test.LCDMonitor", %{})) == expected_reply

    assert unpack_interface_values(Device.get_interface_values!("autotestrealm", "f0VMRgIBAQAAAAAAAAAAAAIAPgABAAAAsCVAAAAAAABAAAAAAAAAADDEAAAAAAAAAAAAAEAAOAAJ", "com.test.LCDMonitor", "time", %{})) ==  %{"from" => 8, "to" => 20}
    assert unpack_interface_values(Device.get_interface_values!("autotestrealm", "f0VMRgIBAQAAAAAAAAAAAAIAPgABAAAAsCVAAAAAAABAAAAAAAAAADDEAAAAAAAAAAAAAEAAOAAJ", "com.test.LCDMonitor", "time/from", %{})) ==  8

    assert_raise DeviceNotFoundError, fn ->
      Device.get_interface_values!("autotestrealm", "g0VMRgIBAQAAAAAAAAAAAAIAPgABAAAAsCVAAAAAAABAAAAAAAAAADDEAAAAAAAAAAAAAEAAOAAJ", "com.test.LCDMonitor", "time/from", %{})
    end

    assert_raise InterfaceNotFoundError, fn ->
      Device.get_interface_values!("autotestrealm", "f0VMRgIBAQAAAAAAAAAAAAIAPgABAAAAsCVAAAAAAABAAAAAAAAAADDEAAAAAAAAAAAAAEAAOAAJ", "com.test.Missing", "weekSchedule/3/start", %{})
    end

    assert_raise EndpointNotFoundError, fn ->
      Device.get_interface_values!("autotestrealm", "f0VMRgIBAQAAAAAAAAAAAAIAPgABAAAAsCVAAAAAAABAAAAAAAAAADDEAAAAAAAAAAAAAEAAOAAJ", "com.test.LCDMonitor", "time/missing", %{})
    end

    assert_raise PathNotFoundError, fn ->
      Device.get_interface_values!("autotestrealm", "f0VMRgIBAQAAAAAAAAAAAAIAPgABAAAAsCVAAAAAAABAAAAAAAAAADDEAAAAAAAAAAAAAEAAOAAJ", "com.test.LCDMonitor", "weekSchedule/9/start", %{})
    end
  end

  test "get_interface_values! returns interfaces values on individual datastream interface" do
    expected_reply = [
      %{"timestamp" => %DateTime{calendar: Calendar.ISO, day: 28, hour: 4, microsecond: {0, 3}, minute: 5, month: 9, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"}, "value" => 0},
      %{"timestamp" => %DateTime{calendar: Calendar.ISO, day: 28, hour: 4, microsecond: {0, 3}, minute: 6, month: 9, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"}, "value" => 1},
      %{"timestamp" => %DateTime{calendar: Calendar.ISO, day: 28, hour: 4, microsecond: {0, 3}, minute: 7, month: 9, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"}, "value" => 2},
      %{"timestamp" => %DateTime{calendar: Calendar.ISO, day: 29, hour: 5, microsecond: {0, 3}, minute: 7, month: 9, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"}, "value" => 3},
      %{"timestamp" => %DateTime{calendar: Calendar.ISO, day: 30, hour: 7, microsecond: {0, 3}, minute: 10, month: 9, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"}, "value" => 4}
    ]
    assert unpack_interface_values(Device.get_interface_values!("autotestrealm", "f0VMRgIBAQAAAAAAAAAAAAIAPgABAAAAsCVAAAAAAABAAAAAAAAAADDEAAAAAAAAAAAAAEAAOAAJ", "com.test.SimpleStreamTest", "0/value", %{})) == expected_reply

    expected_reply = [
      %{"timestamp" => %DateTime{calendar: Calendar.ISO, day: 30, hour: 7, microsecond: {0, 3}, minute: 10, month: 9, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"}, "value" => 4},
      %{"timestamp" => %DateTime{calendar: Calendar.ISO, day: 29, hour: 5, microsecond: {0, 3}, minute: 7, month: 9, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"}, "value" => 3}
    ]
    assert unpack_interface_values(Device.get_interface_values!("autotestrealm", "f0VMRgIBAQAAAAAAAAAAAAIAPgABAAAAsCVAAAAAAABAAAAAAAAAADDEAAAAAAAAAAAAAEAAOAAJ", "com.test.SimpleStreamTest", "0/value", %{"limit" => 2})) == expected_reply

    expected_reply = [
      %{"timestamp" => %DateTime{calendar: Calendar.ISO, day: 28, hour: 4, microsecond: {0, 3}, minute: 6, month: 9, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"}, "value" => 1},
      %{"timestamp" => %DateTime{calendar: Calendar.ISO, day: 28, hour: 4, microsecond: {0, 3}, minute: 7, month: 9, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"}, "value" => 2},
      %{"timestamp" => %DateTime{calendar: Calendar.ISO, day: 29, hour: 5, microsecond: {0, 3}, minute: 7, month: 9, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"}, "value" => 3}
    ]
    opts = %{"since" => "2017-09-28T04:06:00.000Z", "to" => "2017-09-30T07:10:00.000Z"}
    assert unpack_interface_values(Device.get_interface_values!("autotestrealm", "f0VMRgIBAQAAAAAAAAAAAAIAPgABAAAAsCVAAAAAAABAAAAAAAAAADDEAAAAAAAAAAAAAEAAOAAJ", "com.test.SimpleStreamTest", "0/value", opts)) == expected_reply

    expected_reply = [
      %{"timestamp" => %DateTime{calendar: Calendar.ISO, day: 28, hour: 4, microsecond: {0, 3}, minute: 6, month: 9, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"}, "value" => 1},
      %{"timestamp" => %DateTime{calendar: Calendar.ISO, day: 28, hour: 4, microsecond: {0, 3}, minute: 7, month: 9, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"}, "value" => 2}
    ]
    opts = %{"since" => "2017-09-28T04:06:00.000Z", "to" => "2017-09-30T07:10:00.000Z", "limit" => 2}
    assert unpack_interface_values(Device.get_interface_values!("autotestrealm", "f0VMRgIBAQAAAAAAAAAAAAIAPgABAAAAsCVAAAAAAABAAAAAAAAAADDEAAAAAAAAAAAAAEAAOAAJ", "com.test.SimpleStreamTest", "0/value", opts)) == expected_reply

    expected_reply = [
      %{"timestamp" => %DateTime{calendar: Calendar.ISO, day: 28, hour: 4, microsecond: {0, 3}, minute: 7, month: 9, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"}, "value" => 2}
    ]
    opts = %{"since_after" => "2017-09-28T04:06:00.000Z", "to" => "2017-09-30T07:10:00.000Z", "limit" => 1}
    assert unpack_interface_values(Device.get_interface_values!("autotestrealm", "f0VMRgIBAQAAAAAAAAAAAAIAPgABAAAAsCVAAAAAAABAAAAAAAAAADDEAAAAAAAAAAAAAEAAOAAJ", "com.test.SimpleStreamTest", "0/value", opts)) == expected_reply

    #format option tests

    expected_reply = {
      :ok,
      %Astarte.AppEngine.API.Device.InterfaceValues{
        metadata: %{
          "columns" => %{"timestamp" => 0, "value" => 1},
          "table_header" => ["timestamp", "value"]
        },
        data: [
          [%DateTime{calendar: Calendar.ISO, day: 28, hour: 4, microsecond: {0, 3}, minute: 5, month: 9, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"}, 0],
          [%DateTime{calendar: Calendar.ISO, day: 28, hour: 4, microsecond: {0, 3}, minute: 6, month: 9, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"}, 1],
          [%DateTime{calendar: Calendar.ISO, day: 28, hour: 4, microsecond: {0, 3}, minute: 7, month: 9, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"}, 2],
          [%DateTime{calendar: Calendar.ISO, day: 29, hour: 5, microsecond: {0, 3}, minute: 7, month: 9, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"}, 3],
          [%DateTime{calendar: Calendar.ISO, day: 30, hour: 7, microsecond: {0, 3}, minute: 10, month: 9, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"}, 4]
        ]
      }
    }
    opts = %{"format" => "table"}
    assert Device.get_interface_values!("autotestrealm", "f0VMRgIBAQAAAAAAAAAAAAIAPgABAAAAsCVAAAAAAABAAAAAAAAAADDEAAAAAAAAAAAAAEAAOAAJ", "com.test.SimpleStreamTest", "0/value", opts) == expected_reply

    expected_reply = %{
      "value" => [
        [0, %DateTime{calendar: Calendar.ISO, day: 28, hour: 4, microsecond: {0, 3}, minute: 5, month: 9, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"}],
        [1, %DateTime{calendar: Calendar.ISO, day: 28, hour: 4, microsecond: {0, 3}, minute: 6, month: 9, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"}],
        [2, %DateTime{calendar: Calendar.ISO, day: 28, hour: 4, microsecond: {0, 3}, minute: 7, month: 9, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"}],
        [3, %DateTime{calendar: Calendar.ISO, day: 29, hour: 5, microsecond: {0, 3}, minute: 7, month: 9, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"}],
        [4, %DateTime{calendar: Calendar.ISO, day: 30, hour: 7, microsecond: {0, 3}, minute: 10, month: 9, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"}]
      ]
    }
    opts = %{"format" => "disjoint_tables"}
    assert unpack_interface_values(Device.get_interface_values!("autotestrealm", "f0VMRgIBAQAAAAAAAAAAAAIAPgABAAAAsCVAAAAAAABAAAAAAAAAADDEAAAAAAAAAAAAAEAAOAAJ", "com.test.SimpleStreamTest", "0/value", opts)) == expected_reply

    #exception tests

    assert_raise DeviceNotFoundError, fn ->
      Device.get_interface_values!("autotestrealm", "g0VMRgIBAQAAAAAAAAAAAAIAPgABAAAAsCVAAAAAAABAAAAAAAAAADDEAAAAAAAAAAAAAEAAOAAJ", "com.test.SimpleStreamTest", "0/value", %{})
    end

    assert_raise InterfaceNotFoundError, fn ->
      Device.get_interface_values!("autotestrealm", "f0VMRgIBAQAAAAAAAAAAAAIAPgABAAAAsCVAAAAAAABAAAAAAAAAADDEAAAAAAAAAAAAAEAAOAAJ", "com.test.Missing", "0/value", %{})
    end

    assert_raise EndpointNotFoundError, fn ->
      Device.get_interface_values!("autotestrealm", "f0VMRgIBAQAAAAAAAAAAAAIAPgABAAAAsCVAAAAAAABAAAAAAAAAADDEAAAAAAAAAAAAAEAAOAAJ", "com.test.SimpleStreamTest", "missing/endpoint/test", %{})
    end

    assert_raise PathNotFoundError, fn ->
      Device.get_interface_values!("autotestrealm", "f0VMRgIBAQAAAAAAAAAAAAIAPgABAAAAsCVAAAAAAABAAAAAAAAAADDEAAAAAAAAAAAAAEAAOAAJ", "com.test.SimpleStreamTest", "100/value", %{})
    end
  end


  test "get_interface_values! returns interfaces values on object datastream interface" do
    test = "autotestrealm"
    device_id = "f0VMRgIBAQAAAAAAAAAAAAIAPgABAAAAsCVAAAAAAABAAAAAAAAAADDEAAAAAAAAAAAAAEAAOAAJ"

    expected_reply = [
      %{"string" => "aaa", "value" => 1.1, "timestamp" => elem(DateTime.from_iso8601("2017-09-30 07:10:00.000Z"), 1)},
      %{"string" => "bbb", "value" => 2.2, "timestamp" => elem(DateTime.from_iso8601("2017-09-30 07:12:00.000Z"), 1)},
      %{"string" => "ccc", "value" => 3.3, "timestamp" => elem(DateTime.from_iso8601("2017-09-30 07:13:00.000Z"), 1)}
    ]

    assert unpack_interface_values(Device.get_interface_values!(test, device_id, "com.example.TestObject", %{})) == expected_reply

    expected_reply = [
      %{"string" => "bbb", "value" => 2.2, "timestamp" => elem(DateTime.from_iso8601("2017-09-30 07:12:00.000Z"), 1)},
      %{"string" => "ccc", "value" => 3.3, "timestamp" => elem(DateTime.from_iso8601("2017-09-30 07:13:00.000Z"), 1)}
    ]
    opts = %{"since" => "2017-09-30 07:12:00.000Z"}
    assert unpack_interface_values(Device.get_interface_values!(test, device_id, "com.example.TestObject", opts)) == expected_reply

    expected_reply = [
      %{"string" => "ccc", "value" => 3.3, "timestamp" => elem(DateTime.from_iso8601("2017-09-30 07:13:00.000Z"), 1)}
    ]
    opts = %{"since_after" => "2017-09-30 07:12:00.000Z"}
    assert unpack_interface_values(Device.get_interface_values!(test, device_id, "com.example.TestObject", opts)) == expected_reply

    expected_reply = [
      %{"string" => "ccc", "value" => 3.3, "timestamp" => elem(DateTime.from_iso8601("2017-09-30 07:13:00.000Z"), 1)},
      %{"string" => "bbb", "value" => 2.2, "timestamp" => elem(DateTime.from_iso8601("2017-09-30 07:12:00.000Z"), 1)}
    ]
    opts = %{"limit" => 2}
    assert unpack_interface_values(Device.get_interface_values!(test, device_id, "com.example.TestObject", opts)) == expected_reply

    expected_reply = [
      %{"string" => "bbb", "value" => 2.2, "timestamp" => elem(DateTime.from_iso8601("2017-09-30 07:12:00.000Z"), 1)}
    ]
    opts = %{"since" => "2017-09-30 07:12:00.000Z", "to" => "2017-09-30 07:13:00.000Z"}
    assert unpack_interface_values(Device.get_interface_values!(test, device_id, "com.example.TestObject", opts)) == expected_reply

    opts = %{"since" => "2017-09-30 07:12:00.000Z", "limit" => 1}
    assert unpack_interface_values(Device.get_interface_values!(test, device_id, "com.example.TestObject", opts)) == expected_reply

    # format option tests

    expected_reply = {
      :ok,
      %Astarte.AppEngine.API.Device.InterfaceValues{
        data: [
          [elem(DateTime.from_iso8601("2017-09-30 07:10:00.000Z"), 1), "aaa", 1.1],
          [elem(DateTime.from_iso8601("2017-09-30 07:12:00.000Z"), 1), "bbb", 2.2],
          [elem(DateTime.from_iso8601("2017-09-30 07:13:00.000Z"), 1), "ccc", 3.3]
        ],
        metadata: %{
          "columns" => %{"string" => 1, "timestamp" => 0, "value" => 2},
          "table_header" => ["timestamp", "string", "value"]
        }
      }
    }
    opts = %{"format" => "table"}
    assert Device.get_interface_values!(test, device_id, "com.example.TestObject", opts) == expected_reply

    expected_reply = %{
      "string" => [["aaa", elem(DateTime.from_iso8601("2017-09-30 07:10:00.000Z"), 1)], ["bbb", elem(DateTime.from_iso8601("2017-09-30 07:12:00.000Z"), 1)], ["ccc", elem(DateTime.from_iso8601("2017-09-30 07:13:00.000Z"), 1)]],
      "value" => [[1.1, elem(DateTime.from_iso8601("2017-09-30 07:10:00.000Z"), 1)], [2.2, elem(DateTime.from_iso8601("2017-09-30 07:12:00.000Z"), 1)], [3.3, elem(DateTime.from_iso8601("2017-09-30 07:13:00.000Z"), 1)]]
    }
    opts = %{"format" => "disjoint_tables"}
    assert unpack_interface_values(Device.get_interface_values!(test, device_id, "com.example.TestObject", opts)) == expected_reply
  end

  test "list_devices/1 returns all devices" do
    assert_raise DevicesListingNotAllowedError, fn ->
      Device.list_devices!("autotestrealm")
    end
  end

  test "get_device_status!/2 returns the device_status with given id" do
    expected_device_status = %DeviceStatus{
      connected: false,
      id: "f0VMRgIBAQAAAAAAAAAAAAIAPgABAAAAsCVAAAAAAABAAAAAAAAAADDEAAAAAAAAAAAAAEAAOAAJ",
      last_connection: %DateTime{calendar: Calendar.ISO, microsecond: {0, 3}, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, zone_abbr: "UTC", day: 28, hour: 3, minute: 45, month: 9, year: 2017},
      last_disconnection: %DateTime{calendar: Calendar.ISO, microsecond: {0, 3}, month: 9, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC", day: 29, hour: 18, minute: 25},
      first_pairing: %DateTime{calendar: Calendar.ISO, microsecond: {0, 3}, second: 0, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, zone_abbr: "UTC", day: 20, hour: 9, minute: 44, month: 8, year: 2016},
      last_pairing_ip: "4.4.4.4",
      last_seen_ip: "8.8.8.8",
      total_received_bytes: 4500000,
      total_received_msgs: 45000
    }

    assert Device.get_device_status!("autotestrealm", expected_device_status.id) == expected_device_status
  end

  defp unpack_interface_values({:ok, %InterfaceValues{data: values}}) do
    values
  end
end