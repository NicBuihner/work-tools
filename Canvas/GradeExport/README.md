# Overview

Friends in a neighboring district asked for a PowerShell script that would crawl through a Canvas account and export the current grades.

# Requirements

* PowerShell
* Canvas Bearer Token
* CSV knowledge

[You will need to issue yourself a Bearer token](https://community.canvaslms.com/t5/Admin-Guide/How-do-I-manage-API-access-tokens-as-an-admin/ta-p/89) so that the script has permission to call the API endpoints.

You will need to provide the URL for your Canvas instance so that the script knows how to build the correct URLs to get your data. Comments inside the script will tell you more.

If you have a list of specific sisCourseIds that you want to get grades for, you can enter those one per line into a file and then use the sisCourses flag to let the script know about it. If you leave this blank it will export all grades from all courses.

Time. This can take a long time for large Canvas accounts. If you're using some method to generate and upload courses you can save a lot of time by exporting your generated sisCourseIds and using that feature of the script to limit the results that are queried.

# What?

## Canvas

[Canvas](https://www.instructure.com/) is a [learning management system (LMS)](https://en.wikipedia.org/wiki/Learning_management_system) developed by Instructure. It's a generic platform that seems to be very well adapted to deliver a broad range of content. I admit though, that I do not use the client facing portion of the app much, but what I hear is mostly positive.

Their API and authn/authz though is top notch. Educational vendors that use OAuth or OIDC correctly are few and far between. Canvas gets high marks across the board, losing a bit for their lack of swagger/OpenAPI maintenance. But the [documentation](https://canvas.instructure.com/doc/api/) is good, the endpoints give me access to everything I need, and they handle authn/authz appropriately. They're lightyears ahead of most education vendors with the tech, just wish they'd build out an SIS on similar principals so we can dump the hot garbage we've all been having to deal with on that front for the last 20 years.

# Why?

## PowerShell?
The people that asked for this tool are more comfortable using and maintaining PowerShell tools, so that's why PowerShell. PowerShell isn't high up on my frequently used tool list so if you see something wrong or a way to improve something please contribute!

## Current Grade?
This is a little more specific to people familiar with Canvas data. Most of the places where you see grades in Canvas, the data has two versions of two formats. Score is the a number that represents the percentage of points earned to total points. Grade is the letter grade that score would earn based on the scale ofr the gradebook. Either can be absent for various reasons.

* Current
  * Score
  * Grade
* Final
  * Score
  * Grade

Early on in my interactions with Canvas, I attempted to export grades for report cards from the final grade/score which was a disaster. Teachers, students, and parents flooded the help lines with claims that grades were incorrect.

It ended up that final grade does some calculation that has a potential to make it different from the grade that appears in the gradebook. The grade visible to teacher, student, and observers (ususally parents in our case) depending on how various gradebook settings were set.

So, we reran our mass export using the current versions of the grades and the riots ceased. Since then, because the final score can differ from the grades that are displayed, we just never use it and recommend against its use to everyone that asks. It might have some uses in some circumstances, but in our experience the grade we load into a report card needs to match exactly what people are seeing when they check portals.