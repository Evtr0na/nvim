@echo off

set "SERVER=127.0.0.1:6666"
set "FILE=%~1"
set "LINE=%~2"
set "COL=%~3"

if "%LINE%"=="" set "LINE=1"
if "%COL%"=="" set "COL=1"

nvim --server %SERVER% --remote-expr "[execute('drop ' . fnameescape('%FILE%')), cursor(%LINE%, %COL%)]" >nul 2>&1

exit /b 0
