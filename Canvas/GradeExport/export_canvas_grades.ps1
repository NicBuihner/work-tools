# Path to a file that contains a list of sisCourseIds, one per line
param (
    [string]$sisCourses = ""
)

# Use environment variables for the canvas token and url
# Example URL: https://example.instructure.com/api/v1
if (($Env:CANVAS_TOKEN -eq "") -or ($Env:CANVAS_URL -eq "")) {
    # If you don't want to set the environment variables you can 
    # put the values into the following varables
    $Env:CANVAS_TOKEN = ""
    $Env:CANVAS_URL = ""
}

if (($Env:CANVAS_TOKEN -eq "") -or ($Env:CANVAS_URL -eq "")) {
    Write-Error "The CANVAS_TOKEN and CANVAS_URL environment variables must be set in the environment or in the script above."
}

# The authorization header required to query the Canvas API
$headers = @{
    "Authorization" = "Bearer $Env:CANVAS_TOKEN"
}

# Parse the 'Link' header in the response to get the next page of results if any
function Get-NextLink ($respHeaders) {
    $nextLink = ""
    if (!($respHeaders.ContainsKey("Link"))) {
        return ""
    }
    ForEach ($part in $respHeaders.Link.Split(",")) {
        if ($part -Like '*rel="next"') {
            $nextLink = ($part.Split("; ")[0] -Replace '[<>]', '')
        }
    }
    return $nextLink
}

# Retrieve N pages of results from the Canvas API starting from the first page
function Get-CanvasPages ($nextPage) {
    $results = ("[]" | ConvertFrom-JSON)
    while ($nextPage -ne "") {
        Write-Host "Getting -> $nextPage"
        $resp = Invoke-WebRequest `
            -Uri $nextPage `
            -MaximumRetryCount 3 `
            -Headers $headers
        $results += ($resp | ConvertFrom-JSON)
        $nextPage = Get-NextLink($resp.Headers)
    }
    return $results
}

# Retrieve a list of courses. Required because the user query doesn't include 
# all the required term or section information
function Export-CanvasCourses () {
    $courses = @()
    # Get all courses because we weren't given a list of sis_course_ids
    if ($sisCourses -eq "") {
        Write-Host ("Getting all Canvas courses. This can take a while.")
        $accounts = Get-CanvasPages("$Env:CANVAS_URL/api/v1/accounts")
        ForEach ($account in $accounts) {
            $theseCourses = Get-CanvasPages("$Env:CANVAS_URL/api/v1/accounts/{0}/courses?include=term&per_page=100" -f $account.id)
            $courses += $theseCourses
        }
    # Or use the provided list of sis_course_ids, one per line, to determine our 
    # query list
    } else {
        # The file must exist
        if (!(Test-Path $sisCourses -PathType Leaf)) {
            Write-Error ("`"{0}`" not found" -f $sisCourses)
        }
        Write-Host ("Using `"{0}`" as sis_course_id list." -f $sisCourses)
        ForEach ($course in Get-Content $sisCourses) {
            $thisCourse = Get-CanvasPages("$Env:CANVAS_URL/api/v1/courses/sis_course_id:{0}?include[]=term&include[]=sections" -f $course)
            $courses += $thisCourse
        }
    }
    return $courses
}

# Use a list of Canvas courses to query the grades for the students in the course
function Export-CanvasGrades ($courses) {
    ForEach ($course in $courses) {
        $thisCourseUsers = Get-CanvasPages("$Env:CANVAS_URL/api/v1/courses/sis_course_id:{0}/users?include[]=enrollments&enrollment_type[]=student" -f $course.sis_course_id)
        $course | Add-Member -MemberType NoteProperty -Name Enrollment -Value $thisCourseUsers
    }
    return $courses
}

$today = Get-Date -Format "yyyyMMdd"
$courses = Export-CanvasCourses
$grades = Export-CanvasGrades($courses)

if (!(Test-Path -PathType Container -Path ".\temp")) {
    New-Item -ItemType Directory -Force -Path ".\temp"
}
$grades | ConvertTo-Json -Depth 10 > (".\temp\{0}_CoursesDump.json" -f $today)

# Convert the giant dictionary of data we've queried into the required .csv format
$rows = @()
ForEach ($course in $grades) {
    # Write-Host ("{0}:" -f $course.name)
    $course_name = $course.name
    $course_id = $course.sis_course_id
    $term_name = $course.term.name
    $term_id = $course.term.sis_term_id
    ForEach ($student in $course.Enrollment) {
        # Write-Host ("`t{0}" -f $student.sis_user_id)
        $student_id = $student.sis_user_id
        $current_grade = $student.enrollments[0].grades.current_grade
        $current_score = $student.enrollments[0].grades.current_score
        $section_name = ""
        ForEach ($sec in $course.sections) {
            if ($sec.id -eq $student.enrollments[0].course_section_id) {
                $section_name = $sec.name
            }
        }
        $section_id = $student.enrollments[0].sis_section_id
        $rows += [PSCustomObject] @{
            student_sis = $student_id
            course = $course_name
            course_sis = $course_id
            section = $section_name
            section_sis = $section_id
            term = $term_name
            term_sis = $term_id
            current_score = $current_score
            current_grade = $current_grade
        }
    }
}

# Annnnd export it to a csv.
$rows.GetEnumerator() | ConvertTo-Csv > "CanvasGrades_$today.csv"