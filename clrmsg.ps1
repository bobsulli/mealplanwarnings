# clrmsg.ps1 by Bob Sullivan for Salve Regina University
# purpose: clears existing Meal Plan Warnings and sets new Meal Plan Warnings in Heartland 1Card
# Windows Task "HeartlandClearMessages" runs this script on SRUHLOCT01 daily under GO\bob.sullivan
#   at 10:57:00 daily (10:57 AM) ahead of lunch meal period which starts at 11:00 AM
#   at 15:57:00 daily (03:57 PM) ahead of dinner meal period which starts at 04:00 PM
#   at 20:27:00 daily (08:27 PM) ahead of night meal period which starts at 08:30 PM (was 07:30 PM until Fall 2018)
#   at 06:57:00 daily (06:57 AM) ahead of breakfast meal period starts at 7:00 AM

# set file name based on job run time
Function Set-Meal-File ($file) {
$curhour = (Get-Date -Format "HH") # get current hour 
If ($curhour -eq "10") 
    {
    $filenum = "1"
    }
ElseIf ($curhour -eq "15") 
    { 
    $filenum = "2" 
    }
ElseIf ($curhour -eq "20")
    {
    $filenum = "3" 
    }
ElseIf ($curhour -eq "06") 
    { 
    $filenum = "4"
    }
Else 
    {
    $filenum = "0" # only for testing at hours NOT on job schedule
    }
$file = $file + $filenum + ".TXT"
Return $file
}

$basecamp = "C:\Users\bob.sullivan\clrmsg\"
$log = $basecamp + "clrmsg.log"
$taskout = "O:\1Card\1Card\REPORT\" # TASK writes its reports here
$mailin = "O:\1Card\1Card\MAIL" # polling directory for Heartland DataConnect a/k/a MAIL
$jobstart = Get-Date -Format "yyyy/MM/dd HH:mm"

# NET USE O: \\sruhlapp01\1card$ in C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\1Card_Connect.bat
New-PSDrive -Name O -PSProvider FileSystem -Root \\SRUHLAPP01\1card$ -description Heartland
If (Test-Path $mailin) 
    {
    "clrmsg started at {0}" -f $jobstart >>$log
    }
Else 
    {
    "clrmsg failed at {0} missing Heartland O: drive" -f $jobstart >>$log
    Exit
    }

# clear existing Meal Plan Warnings using content of report #010104 "Listing Of Messages Ordered By Account Number"
#   saved with parameters (per Report Data in Edit Task Dialog)
#   1) Type Report = CommaDelimited
#   2) Selected Report = TRUE
#   3) Only Summary = FALSE
#   fields in #010104 are in this order: Account, Message Type, Msg Date, Message Text
#   do not use report #010105 it has same fields but different order Message Type, Account, Msg Date, Message Text
#   both reports found under 1Card -> Report -> Library Reports -> All Above Areas
# Heartland 1Card TASK on SRUHLAPP01 is set to run these saved reports:
#   MsgListByAcct1 generates output file MsgListAcct1.TXT at 10:55:00 daily (10:55 AM)
#   MsgListByAcct2 generates output file MsgListAcct2.TXT at 15:55:00 daily (03:55 PM)
#   MsgListByAcct3 generates output file MsgListAcct3.TXT at 20:25:00 daily (08:25 PM was 07:25 PM until Fall 2018)
#   MsgListByAcct4 generates output file MsgListAcct4.TXT at 06:55:00 daily (06:55 AM)
$outfile = $basecamp + "clrmsg.CNM" # extension=CNM for production or TXT for testing

# set file name based on job run time
$infile = $taskout + (Set-Meal-File("MsgListAcct"))

$clearing = 0 # number of messages to clear
if (Test-Path $infile) 
    {
    "Message Listing {0} found" -f $infile >>$log
    If (Test-Path $outfile)
        {
        Remove-Item $outfile
        }
    # convert Message Listing by Account into OneCard Data Connect (a/k/a MAIL) file
    $data = Get-Content $infile
    $data | foreach {
        $items = $_.split(",")
        # only process meal warnings (and skip time stamp at end of report, too)
        if ($items[1] -eq "5 - MEAL PLAN WARNING") 
            {
            $clearing++
            # strip spaces from account number an precede with an asterisk
            $acct = $items[0].Substring(0,11) -replace ' ','' # strip spaces from account number
            '*{0}' -f $acct >>$outfile
            # precede message text with function 27 to Remove messages of type 5 (Meal Plan Warning) by Leading comparison
            '27,5,RL,{0}' -f $items[3] >>$outfile
            }
        }
    }
Else 
    { 
    "Message Listing {0} not found" -f $infile >>$log
    }
# if messages to clear then copy to OneCard DataConnect polling directory for immediate processing
If ($clearing -gt 0) 
    {
    Copy-Item $outfile -Destination $mailin
    "copied {0} to {1} to clear {2} meal plan warnings" -f $outfile, $mailin, $clearing >>$log
    }
Else
    {
    "no meal plan warnings to clear" >>$log
    }

# do not set Meal Plan Warnings on Fridays (cannot exceed 5 meals/week until after Saturday lunch meal period)
# more significantly, reports have to be resaved on Fridays to use new Start Date
$dow = Get-Date -Format "ddd" # -UFormat "%u"
If ($dow -eq "Fri")
    {
    "skip Meal Plan Warnings on {0}" -f $dow >>$log
    Exit
    }
Else
    {
    "set Meal Plan Warnings on {0}" -f $dow >>$log
    }

# set new Meal Plan Warnings using content from report #002005 "Low Meals Report (Flexible Weekly Plans)"
#   saved with parameters (per Report Data in Edit Task Dialog)
#   1) Selected Meal Plans = All Meal Plans
#   2) Report Option = Account Name First
#   3) Skip Unused Meal Plans = Yes
#   4) Left Meals = 1
#   5) OutPut Mode = WordPad
#   6) Output File LowMeals.TXT (sequenced for multiple runs)
#   report found under 1Card -> Report -> Dining Reports as "Remaining Meals (Weekly Plans - Types 2,8,9)"
#   fields in #002005 are Name, ID Number, Meals Left grouped by Meal Plan
# Heartland 1Card TASK on SRUHLAPP01 is set to run these saved reports:
#   LowMeals1 generates Output File LowMeals1.TXT at 10:56:00 daily (10:56 AM)
#   LowMeals2 generates Output File LowMeals2.TXT as 15:56:00 daily (03:56 PM)
#   LowMeals3 generates Output File LowMeals3.TXT at 20:26:00 daily (08:26 PM was 07:26 PM until Fall 2018)
#   LowMeals4 generates Output File LowMeals4.TXT as 06:56:00 daily (06:56 AM)
$setmsg = $basecamp + "setmsg.CNM" # extension=CNM for production or TXT for testing
$nomeals = $basecamp + "NoMeals.TXT" # customized Low Meals Report
$tempo = $basecamp + "temp.TXT"

# set file name based on job run time
$infile = $taskout + (Set-Meal-File("LowMeals"))
If (Test-Path $infile) 
    {
    "Low Meals Report {0} found" -f $infile >>$log
    }
Else
    { 
    "Low Meals Report {0} not found" -f $infile >>$log
    Exit
    }

If (Test-Path $setmsg) 
    {
    Remove-Item $setmsg
    }
If (Test-Path $nomeals) 
    {
    Remove-Item $nomeals
    }

$newwarns = 0 # count of Meal Plan Warnings built
$i = 0 # for line number within file
$j = 0 # for maximum length of student names
$mealplan = "MEAL PLAN" # place holder
$dateis = Get-Date -Format "MM/dd/yyyy"
$timeis = Get-Date -Format "hh:mm:ss"
$lowmeals = Import-CSV $infile -Header lmr -Delimiter ^
ForEach ($lowmeal in $lowmeals)
    {
    $i++
    # header for No Meals w/sort prefixes to keep them at top of report
    If ($i -eq 1 -or $i -eq 2)
        {
        "{0} {1}" -f $i.ToString("00"), $lowmeal.lmr >>$nomeals
        }
    If ($i -eq 3)
        {
        # place holder for blank line
        "{0} {1}" -f $i.ToString("00"), "@" >>$nomeals
        }
    If ($i -eq 8)
        {
        # add Meal Plans column
        "{0} {1}  {2}" -f $i.ToString("00"), $lowmeal.lmr, "Meal Plan" >>$nomeals
        }
    If ($i -eq 9)
        {
        # add Meal Plans column
        "{0} {1}  {2}" -f $i.ToString("00"), $lowmeal.lmr, "-------------" >>$nomeals
        }
    # get name of meal plan for customized Low Meals Report
    If ($lowmeal.lmr.length -eq 80)
        {
        If ($lowmeal.lmr -match "MEAL PLAN:")
            {
            $mealplan = $lowmeal.lmr.Substring(51,20).Trim()
            }
        }
    # process for no meals left (minimal Low Meals Report has 1 and 0 meals left)
    If ($lowmeal.lmr.length -eq 64)
        {
        If ($lowmeal.lmr.Substring(54,10) -match "         0")
            {
            $newwarns++
            # strip spaces from account number for mode 0 file
            "*{0}" -f $lowmeal.lmr.Substring(41,11) -replace ' ','' >>$setmsg
            # add messsage for mode 0 file
            "26,5,{0},{1},USED UP {2}" -f $dateis, $timeis, $mealplan >>$setmsg
            # detail lines for customized Low Meals Report plus sort prefix (all students are prefix 99)
            "{0} {1}   {2}" -f "99", $lowmeal.lmr, $mealplan >>$nomeals
            }
        }
    }
"built {0} Meal Plan Warnings" -f $newwarns >>$log
If ($newwarns -eq 0) 
    {
    Remove-Item $nomeals
    }
Else
    {
    Copy-Item $setmsg -Destination $mailin
    "copied {0} to {1} to set {2} meal plan warnings" -f $outfile, $mailin, $newwarns >>$log
    # sort custom Low Meals Report alphabetically by student name regardless of meal plan
    Get-Content $nomeals | sort >$tempo
    Remove-Item $nomeals
    $no_meals = Import-CSV $tempo -Header snm -Delimiter ^
    ForEach ($no_meal in $no_meals) 
        {
        If ($no_meal.snm -match "@") 
            {
            # force blank line into output file
            "{0}" -f "" >>$nomeals
            }
        Else 
            {
            # strip sort prefix from custom Low Meals Report
            "{0}" -f $no_meal.snm.Substring(3) >>$nomeals
            }
        }
    Remove-Item $tempo
    # send email with custom Low Meals Report
    $ebody = "Meal Plan Warnings set at {0} {1} for {2} accounts (details are in attachment)." -f $dateis, $timeis, $newwarns
    $extra = "These accounts will show MESSAGE WAITING after swipe/tap at DCT3 or POS."
    # $eto = @("rebecca.webb@salve.edu", "lisa.olivetgallo@salve.edu", "nicole.santaniello@salve.edu", "bob.sullivan@salve.edu")
    $eto = @("bob.sullivan@salve.edu")
    $efrom = "dataconnect@salve.edu"
    $esubj = "Meal Plan Warnings"
    $eport = 25
    $esmtp = "192.168.51.23"
    $efile = $nomeals
    Send-MailMessage -Subject $esubj -Body $ebody -Attachment $efile -From $efrom -To $eto `
      -SmtpServer $esmtp -Port $eport
    "emailed custom Low Meals Report {0}" -f $nomeals >>$log
    }
$jobend = Get-Date -Format "yyyy/MM/dd HH:mm"
"clrmsg completed at {0}" -f $jobend >>$log
# end of clrmsg.ps1 by Bob Sullivan for Salve Regina University
