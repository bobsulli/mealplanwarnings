# mealplanwarnings
clears existing Meal Plan Warnings and sets new Meal Plan Warnings in OneCard

I use a Windows Task "HeartlandClearMessages" (also here as an .XML) to run my clrmsg.ps1 script on a "jump" server under my account multiple times each day:
at 06:57 AM ahead of breakfast meal period starts at 7:00 AM
at 10:57 AM ahead of lunch meal period which starts at 11:00 AM
at 03:57 PM ahead of dinner meal period which starts at 04:00 PM
at 08:27 PM ahead of night meal period which starts at 08:30 PM
If when/meal periods change the corresponding changes are needed in the Set-Meal-File function, which sets file name based on job run time.

To clear existing Meal Plan Warnings, I use content from report #010104 "Listing Of Messages Ordered By Account Number" saved with parameters
(per Report Data in Edit Task Dialog) Type Report = CommaDelimited, Selected Report = TRUE, 3) Only Summary = FALSE. Fields in #010104 are in this order: 
Account, Message Type, Msg Date, Message Text. Do NOT use report #010105, which has same fields in different order (Message Type, Account, Msg Date, Message Text).
Both reports found under 1Card -> Report -> Library Reports -> All Above Areas.

Use OneCard TASK to run saved reports. You will need one before each meal period. My schedule is:
MsgListByAcct1 generates output file MsgListAcct1.TXT at 10:55:00 daily (10:55 AM)
MsgListByAcct2 generates output file MsgListAcct2.TXT at 15:55:00 daily (03:55 PM)
MsgListByAcct3 generates output file MsgListAcct3.TXT at 20:25:00 daily (08:25 PM)
MsgListByAcct4 generates output file MsgListAcct4.TXT at 06:55:00 daily (06:55 AM)

At my campus, meal period runs Friday morning to Thursday evening. I do NOT set Meal Plan Warnings on Fridays for two reasons. 
Most important is the meal plan has to be used for the new Start Date to be available. If dining halls are closed, no one is using meal plan.
Also, it is not possible for any of our meal plans to be used up on the first day.

To set new Meal Plan Warnings, I use content from report #002005 "Low Meals Report (Flexible Weekly Plans)" saved with parameters 
(per Report Data in Edit Task Dialog) Selected Meal Plans = All Meal Plans, Report Option = Account Name First, Skip Unused Meal Plans = Yes, Left Meals = 1,
OutPut Mode = WordPad, Output File LowMeals.TXT (sequenced for multiple runs). This report is found under 1Card -> Report -> Dining Reports as
"Remaining Meals (Weekly Plans - Types 2,8,9)". Fields in report #002005 are Name, ID Number, Meals Left grouped by Meal Plan

Use OneCard TASK to run saved reports. You wil need one before each meal period. My schedule is:
LowMeals1 generates Output File LowMeals1.TXT at 10:56:00 daily (10:56 AM)
LowMeals2 generates Output File LowMeals2.TXT as 15:56:00 daily (03:56 PM)
LowMeals3 generates Output File LowMeals3.TXT at 20:26:00 daily (08:26 PM)
LowMeals4 generates Output File LowMeals4.TXT as 06:56:00 daily (06:56 AM)
