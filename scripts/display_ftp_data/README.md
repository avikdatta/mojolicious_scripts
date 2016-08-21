# Display FTP files
A script for displaying the database contents via a web page

## Usage

<pre><code>
   ./scripts/display_ftp_files.pl daemon -m production  \
        --dbuser dbuser \
        --dbpass dbpass \
        --dbname dbname
</pre></code>

## Access data
### HTML
<pre><code>
  http://127.0.0.1:3000/summary
</pre></code>

### JSON
<pre><code>
  http://192.168.0.11:3000/summary?format=json
</pre></code> 


