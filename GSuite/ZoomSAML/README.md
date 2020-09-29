# Overview

Use Meet. That said, if you are ruled by professional bureaucrats whose
decision making process is as deep as best-of-five shakes of a magic eight
ball, I hope this will ease your pain and assist you in wasting as little
taxpayer money as possible.

I'm assuming that you're using GSuite as your primary IDP and that you will
federating Zoom via SAML. I recommend this over the "Sign in with Google" or
OIDC flow as it allows you more control over user attributes in Zoom. Going
through documentation we identified the following attribute assertions as the
ones that we wanted to send to Zoom:
* Email
* First name
* Last name
* Display name  
  * ZoomDisplayName
* User Type  
  * Basic -> Basic
  * Licensed -> Licensed
* User Role  
  * Member -> Member
  * Admin -> Admin
* User Group  
  * teachers -> teachers
  * students -> students
  * staff -> staff

The first three attributes are already part of our user data in GSuite. The
last four need to be added ie:
```
User:
  CustomSchemas:
  - SAMLAttributes:
    - ZoomDisplayName
    - ZoomType
    - ZoomRole
    - ZoomGroup
```

# Requirements

* [GAM](https://github.com/jay0lee/GAM/wiki) - Activated and ready to go with schema and user scopes.
* sqlite3
* [all_users.db](https://github.com/NicBuihner/work-tools/tree/master/GSuite/Users)

# Steps

## Create the Schema
We need a place to put the attributes in GSuite that we're going to send to
Zoom. Feel free to change **SAMLAttributes** to whatever you feel is
appropriate, but keep it consistent, think about how this schema might be used
later.
```
gam create schema **SAMLAttributes** |\
    field ZoomDisplayName type string endfield |\
    field ZoomType type string endfield |\
    field ZoomRole type string endfield |\
    field ZoomGroup type string endfield
```

## Populate the Student Values
You mean need to tweak the sqlite3 query. Here I assume that your students are all in a root OU **/Student**.
```
sqlite3 -csv all_users.db "select primaryEmail,[name.givenName],[name.surName] from users where orgUnitPath like '/Student%'" |\
    awk -F',' '{print "update user "$1" SAMLAttributes.ZoomDisplayName \x27"$3" "$2"\x27 SAMLAttributes.ZoomType Basic SAMLAttributes.ZoomRole Member SAMLAttributes.ZoomGroup students"}' >\
    student_zoom_attributes.commands
```
Inspect the student_zoom_attributes.commands file for correctness. Once you're sure everything looks good, run them through GAM.
```
< student_zoom_attributes.commands xargs -L1 -P10 gam
```

## Populate the Teacher Values
Assuming your teachers are all in **/Staff/Teaching**.
```
sqlite3 -csv all_users.db "select primaryEmail,[name.givenName],[name.surName] from users where orgUnitPath like '/Staff/Teaching%'" |\
    awk -F',' '{print "update user "$1" SAMLAttributes.ZoomDisplayName \x27"$3" "$2"\x27 SAMLAttributes.ZoomType Licensed SAMLAttributes.ZoomRole Member SAMLAttributes.ZoomGroup teachers"}' >\
    teacher_zoom_attributes.commands
```
Inspect the teacher_zoom_attributes.commands file for correctness. Once you're sure everything looks good, run them through GAM.
```
< teacher_zoom_attributes.commands xargs -L1 -P10 gam
```

## Populate the Staff Values
Assuming your staff are all in **/Staff** and not in **/Staff/Teaching**.
```
sqlite3 -csv all_users.db "select primaryEmail,[name.givenName],[name.surName] from users where orgUnitPath like '/Staff%' and orgUnitPath not like '/Staff/Teaching%'" |\
    awk -F',' '{print "update user "$1" SAMLAttributes.ZoomDisplayName \x27"$3" "$2"\x27 SAMLAttributes.ZoomType Licensed SAMLAttributes.ZoomRole Member SAMLAttributes.ZoomGroup staff"}' >\
    staff_zoom_attributes.commands
```
Inspect the staff_zoom_attributes.commands file for correctness. Once you're sure everything looks good, run them through GAM.
```
< staff_zoom_attributes.commands xargs -L1 -P10 gam
```

# Why?
## The sqlite db?
You can [query for
these](https://developers.google.com/admin-sdk/directory/v1/guides/search-users)
things directly against the users endpoint or with GAM, but it can be slow with
a large domain and the queries aren't as useful.

## The .commands file?
Over the years I've gotten in the habit of generating the work to do as an
explicit step. It's easy to look for things like unmatched quotes and other
weird values that might mess something up. Also makes running partial tests or
re-running easier if there is an issue executing the work. It's also sometimes
helpful to have a log of work done.
