describe :time_local, :shared => true do
  it "creates a time based on given values, interpreted in the local time zone" do
    with_timezone("PST", -8) do
      Time.send(@method, 2000, "jan", 1, 20, 15, 1).to_a.should ==
        [1, 15, 20, 1, 1, 2000, 6, 1, false, "PST"]
    end
  end

  it "respects rare old timezones" do
    with_timezone("Europe/Amsterdam") do
      Time.send(@method, 1910, 1, 1).to_a.should ==
        [0, 0, 0, 1, 1, 1910, 6, 1, false, "AMT"]
    end
  end

  describe "timezone changes" do
    it "correctly adjusts the timezone change to 'EET' on 'Europe/Istanbul'" do
      with_timezone("Europe/Istanbul") do
        Time.send(@method, 1910, 10, 1).to_a.should ==
          [4, 3, 0, 1, 10, 1910, 6, 274, false, "EET"]
      end
    end

    it "correctly adjusts the timezone change to 'WET' on 'Europe/Lisbon'" do
      with_timezone("Europe/Lisbon") do
        Time.send(@method, 1912, 1, 1).to_a.should ==
          [45, 36, 0, 1, 1, 1912, 1, 1, false, "WET"]
      end
    end

    it "correctly adjusts the timezone change to 'CEST' on 'Europe/Amsterdam'" do
      with_timezone("Europe/Amsterdam") do
        Time.send(@method, 1940, 5, 16).to_a.should ==
          [0, 40, 1, 16, 5, 1940, 4, 137, true, "CEST"]
      end
    end
  end
end

describe :time_local_10_arg, :shared => true do
  it "creates a time based on given C-style gmtime arguments, interpreted in the local time zone" do
    with_timezone("America/Los_Angeles") do
      Time.send(@method, 1, 15, 20, 1, 1, 2000, :ignored, :ignored, false, :ignored).to_a.should ==
        [1, 15, 20, 1, 1, 2000, 6, 1, false, "PST"]
    end
  end

  it "creates the correct time just before dst change" do
    with_timezone("America/New_York") do
      time = Time.send(@method, 0, 30, 1, 30, 10, 2005, 0, 0, true, ENV['TZ'])
      time.utc_offset.should == -4 * 3600
    end
  end

  it "creates the correct time just after dst change" do
    with_timezone("America/New_York") do
      time = Time.send(@method, 0, 30, 1, 30, 10, 2005, 0, 0, false, ENV['TZ'])
      time.utc_offset.should == -5 * 3600
    end
  end

end
