state("Game-Win64-Shipping")
{
    string255 level : 0x02F8AB60, 0x3F8, 0x0;
    float xVel : 0x02F6BA98, 0x0, 0xE8, 0x398, 0xD0;
    float yVel : 0x02F6BA98, 0x0, 0xE8, 0x398, 0xD4;
    float gameSpeed : 0x2F8AB60, 0x30, 0x240, 0x308;
    long achi : 0x02F87630, 0x58, 0x3C0;
}

startup
{
    settings.Add("speedometer", true, "Show Speedometer");
    settings.Add("speedround", false, "Round to whole number", "speedometer");
    settings.Add("showMap", false, "Show Map Name");
    vars.currentLevel = "";
    vars.oldLevel = "";

    if (timer.CurrentTimingMethod == TimingMethod.RealTime)
    {
        var timingMessage = MessageBox.Show(
            "This game uses RTA w/o Loads as the main timing method.\n"
            + "LiveSplit is currently set to show Real Time (RTA).\n"
            + "Would you like to set the timing method to RTA w/o Loads?",
            "Ghostrunner | LiveSplit",
            MessageBoxButtons.YesNo, MessageBoxIcon.Question
        );
        if (timingMessage == DialogResult.Yes)
        {
            timer.CurrentTimingMethod = TimingMethod.GameTime;
        }
    }

    vars.SetTextComponent = (Action<string, string>)((id, text) =>
	{
        var textSettings = timer.Layout.Components.Where(x => x.GetType().Name == "TextComponent").Select(x => x.GetType().GetProperty("Settings").GetValue(x, null));
        var textSetting = textSettings.FirstOrDefault(x => (x.GetType().GetProperty("Text1").GetValue(x, null) as string) == id);
        if (textSetting == null)
        {
            var textComponentAssembly = Assembly.LoadFrom("Components\\LiveSplit.Text.dll");
            var textComponent = Activator.CreateInstance(textComponentAssembly.GetType("LiveSplit.UI.Components.TextComponent"), timer);
            timer.Layout.LayoutComponents.Add(new LiveSplit.UI.Components.LayoutComponent("LiveSplit.Text.dll", textComponent as LiveSplit.UI.Components.IComponent));
            textSetting = textComponent.GetType().GetProperty("Settings", BindingFlags.Instance | BindingFlags.Public).GetValue(textComponent, null);
            textSetting.GetType().GetProperty("Text1").SetValue(textSetting, id);
        }
        if (textSetting != null)
            textSetting.GetType().GetProperty("Text2").SetValue(textSetting, text);
	});

    vars.UpdateSpeedometer = (Action<float, float, bool>)((x, y, round) =>
    {
        double hvel = Math.Floor(Math.Sqrt(x*x + y*y)+0.5);
        if(round)
            vars.SetTextComponent("Speed", Math.Floor(hvel/100).ToString("") + " m/s");
        else
            vars.SetTextComponent("Speed", (hvel/100).ToString("0.00") + " m/s");
    });
}

update
{
    if(settings["speedometer"])
        vars.UpdateSpeedometer(current.xVel, current.yVel, settings["speedround"]);

    if(settings["showMap"])
        vars.SetTextComponent("Map", vars.currentLevel);
	
    //todo remove
    vars.SetTextComponent("ACHI", vars.currentAchi.ToString("X"));
    
    if(current.level != null && current.level.Contains("/Game/Maps"))
    {
        vars.oldLevel = vars.currentLevel;
        vars.currentLevel = current.level.Replace("/Game/Maps/", "").Replace("Secrets/", "");
        if(vars.oldLevel != vars.currentLevel)
        {
            vars.pauseUntilLoad = false;
            print(vars.oldLevel+" -> "+vars.currentLevel);
        }
    }
}

start
{
    return vars.oldLevel == "Intro" && vars.currentLevel == "Level00";
}

split
{
    return ((vars.oldLevel != vars.currentLevel && vars.oldLevel != "HUB" && vars.oldLevel != "LevelLoader" && vars.oldLevel != "Test" && vars.oldLevel != "") || (vars.currentLevel == "ApexOutro" && current.gameSpeed == 0.3f && old.gameSpeed == 0.5f));
}

isLoading
{
    return current.level == null;
}

exit
{
    timer.IsGameTimePaused = true;	
}
