docker run -d --name cuber-studio -v /media:/media -v /home/giuliano:/home/giuliano -e USER=rstudio -e USERID=3002 -e GROUPID=3002 -e PASSWORD=testagosto -p 8587:8787 cuber-studio

