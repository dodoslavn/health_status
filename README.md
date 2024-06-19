# Health Status
### What is it?
Its a script which will show you if your OS process is running or not.
### What OS proces?
You define them in 'param' text file, which has CSV syntax.
### How does it tell me if it is running?
This is the important part - in a nice and easy to read table, in CLI.
### How can i run it?
Its Linux bash script. So, you need Linux, lsof and netstat installed.  
Originaly it was developed on AIX, and probably worked on HP-UX too.
### So what is the syntax of the 'param' file?
Syntax came from BlueCare which is IBM monitoring tool, and it uses configuration files with this syntax:  
**unimportant;also_unimportant;process name;user;1;;L;C;;0;6;0000;**  
Only 3th and 4th column is important.
