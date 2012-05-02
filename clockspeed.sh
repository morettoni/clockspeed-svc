#!/bin/sh

# path to rrd db
RRDDB=/var/db/rrd/clockspeed.rrd

# graph & html output dir
OUT=/home/web/rrd/html

# NTP server
NTP=PUT_NTPSERVER_HERE

# max error delta
LIMIT=5000

# clockadjust log output directory
LOG=/service/clockadjust/log/main

### end of config var

# application path, check before use
RRDUPDATE=/usr/local/bin/rrdupdate
RRDTOOL=/usr/local/bin/rrdtool

HOSTNAME=`hostname`

exec 2>/dev/null

read_diff () {
  while true; do
    RES=`/usr/local/bin/sntpclock ${NTP} 2>/dev/null | /usr/local/bin/clockview | tr '\n' '|'`

    MIN_BEFORE=`echo ${RES} | cut -d'|' -f1 | cut -d: -f3`
    MIN_AFTER=`echo ${RES} | cut -d'|' -f2 | cut -d: -f3`

    if [ ${MIN_BEFORE} = ${MIN_AFTER} ]; then
      BEFORE=`echo ${RES} | cut -d'|' -f1 | cut -d: -f4`
      AFTER=`echo ${RES} | cut -d'|' -f2 | cut -d: -f4`
      VALUE=`echo "(${AFTER} - ${BEFORE}) * 1000" | bc | tr -d '-'`
      return
    else
      sleep 1
    fi
  done
}

[ ! -f ${RRDDB} ] && ${RRDTOOL} create ${RRDDB} --start N DS:diff:GAUGE:600:U:U \
	RRA:LAST:0.5:1:600 \
	RRA:LAST:0.5:6:700 \
	RRA:LAST:0.5:24:775 \
	RRA:LAST:0.5:288:797 \
	RRA:AVERAGE:0.5:1:600 \
	RRA:AVERAGE:0.5:6:700 \
	RRA:AVERAGE:0.5:24:775 \
	RRA:AVERAGE:0.5:288:797 \
	RRA:MAX:0.5:1:600 \
	RRA:MAX:0.5:6:700 \
	RRA:MAX:0.5:24:775 \
	RRA:MAX:0.5:288:797

read_diff
${RRDUPDATE} ${RRDDB} N:${VALUE} > /dev/null

${RRDTOOL} graph ${OUT}/clockspeed-hour.png -a PNG -h 125 -s -3600 -v "Clock error (mS)" \
    "DEF:cur=${RRDDB}:diff:LAST" \
    "CDEF:val=cur,0,2500,LIMIT" \
    "LINE2:val#0000FF:diff" "AREA:val#0000FF2f:" \
    "GPRINT:cur:LAST:last\: %7.2lf mS" \
    "GPRINT:val:MAX:max\: %7.2lf mS" \
    "GPRINT:val:AVERAGE:avg\: %7.2lf mS\j" \
> /dev/null

${RRDTOOL} graph ${OUT}/clockspeed-day.png -a PNG -h 125 -s -86400 -v "Clock error (mS)" \
    "DEF:cur=${RRDDB}:diff:LAST" \
    "CDEF:val=cur,0,2500,LIMIT" \
    "LINE1:val#0000FF:diff" "AREA:val#0000FF2f:" \
    "GPRINT:cur:LAST:last\: %7.2lf mS" \
    "GPRINT:val:MAX:max\: %7.2lf mS" \
    "GPRINT:val:AVERAGE:avg\: %7.2lf mS\j" \
> /dev/null

${RRDTOOL} graph ${OUT}/clockspeed-week.png -a PNG -h 125 -s -604800 -v "Clock error (mS)" \
    "DEF:cur=${RRDDB}:diff:LAST" \
    "CDEF:val=cur,0,2500,LIMIT" \
    "LINE1:val#0000FF:diff" "AREA:val#0000FF2f:" \
    "GPRINT:cur:LAST:last\: %7.2lf mS" \
    "GPRINT:val:MAX:max\: %7.2lf mS" \
    "GPRINT:val:AVERAGE:avg\: %7.2lf mS\j" \
> /dev/null

${RRDTOOL} graph ${OUT}/clockspeed-month.png -a PNG -h 125 -s -2592000 -v "Clock error (mS)" \
    "DEF:cur=${RRDDB}:diff:LAST" \
    "CDEF:val=cur,0,2500,LIMIT" \
    "LINE1:val#0000FF:diff" "AREA:val#0000FF2f:" \
    "GPRINT:cur:LAST:last\: %7.2lf mS" \
    "GPRINT:val:MAX:max\: %7.2lf mS" \
    "GPRINT:val:AVERAGE:avg\: %7.2lf mS\j" \
> /dev/null

${RRDTOOL} graph ${OUT}/clockspeed-year.png -a PNG -h 125 -s -31536000 -v "Clock error (mS)" \
    "DEF:cur=${RRDDB}:diff:LAST" \
    "CDEF:val=cur,0,2500,LIMIT" \
    "LINE1:val#0000FF:diff" "AREA:val#0000FF2f:" \
    "GPRINT:cur:LAST:last\: %7.2lf mS" \
    "GPRINT:val:MAX:max\: %7.2lf mS" \
    "GPRINT:val:AVERAGE:avg\: %7.2lf mS\j" \
> /dev/null

EXTRA=""
if [ -f ${LOG}/current ]; then
  EXTRA="<BR><I>Last clock update: `tail -n1 ${LOG}/current | cut -d' ' -f1 | /usr/local/bin/tai64nlocal`</I>"
fi

cat <<EOF > ${OUT}/index.html
<HTML>
<HEAD>
<TITLE>${HOSTNAME} clockspeed stats</TITLE>
<META HTTP-EQUIV="Refresh" CONTENT="600">
</HEAD>
<BODY>
<H1>${HOSTNAME} clockspeed stats</H1>
<I>Last update: `date "+%Y-%m-%d %H:%M:%S.000000000"`</I>${EXTRA}
<HR>
<TABLE BORDER="0">
 <TR>
  <TD>
   <B>Clockspeed error (one hour)</B><BR>
   <IMG src="clockspeed-hour.png" alt="Clockspeed error (one hour)">
  </TD>
  <TD>
   <B>Clockspeed error (one day)</B><BR>
   <IMG src="clockspeed-day.png" alt="Clockspeed error (one day)">
  </TD>
 </TR>
 <TR>
  <TD>
   <B>Clockspeed error (one week)</B><BR>
   <IMG src="clockspeed-week.png" alt="Clockspeed error (one week)">
  </TD>
  <TD>
   <B>Clockspeed error (one month)</B><BR>
   <IMG src="clockspeed-month.png" alt="Clockspeed error (one month)">
  </TD>
 </TR>
 <TR>
  <TD>
   <B>Clockspeed error (one year)</B><BR>
   <IMG src="clockspeed-year.png" alt="Clockspeed error (one year)">
  </TD>
  <TD>
   &nbsp;
  </TD>
 </TR>
</TABLE>
<HR>
<ADDRESS>This page was generated with a software developed by <A HREF="http://morettoni.net/">Luca Morettoni</A></ADDRESS>
</BODY>
</HTML>
EOF
