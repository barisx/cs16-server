<?php
    
    // insert SQL info here (inside the empty "")
    define( "SQL_HOST", "" );
    define( "SQL_USER", "" );
    define( "SQL_PASS", "" );
    define( "SQL_DB", "" );
    
    // decimal places displayed
    define( "TIME_DECIMAL_PLACES", "2" );
    
?>
<html>
<head>
    <style type="text/css">
        body {
            background-color: #94AEC6;
        }
        
        h3 {
            text-align: center;
        }
        
        a:link, a:visited, a:active {
            color: #304759;
            text-decoration: underline;
        }
        
        a:hover {
            color: #52697B;
            text-decoration: underline;
        }
        
        table {
            width: 100%;
        }
        
        tr {
            text-align: center;
        }
        
        tr.header {
            background-color: #52697B;
        }
        
        tr.header a:link, tr.header a:visited, tr.header a:active {
            color: #000;
        }
        
        tr.header a:hover {
            color: #304759;
        }
        
        tr.alt {
            background-color: #B0C4DE;
        }
        
        tr#pos1 {
            background-color: #f00;
        }
        
        tr#pos2 {
            background-color: #07fcff;
        }
        
        tr#pos3 {
            background-color: #fff007;
        }
        
        .pos {
            width: 5%;
        }
        
        .name {
            text-align: left;
            width: 30%;
        }
        
        .time {
            width: 25%;
        }
        
        .cp {
            width: 20%;
        }
        
        .gc {
            width: 20%;
        }
        
        .map {
            text-align: left;
            width: 60%;
        }
        
        .toplink {
            width: 20%;
        }
        
        p {
            text-align: center;
        }
    </style>
</head>
<body>
<?php
    
    $sql_conn = mysql_connect( SQL_HOST, SQL_USER, SQL_PASS );
    
    if( $sql_conn && mysql_select_db( SQL_DB, $sql_conn ) )
    {
        if( isset( $_GET[ 'map' ] ) && isset( $_GET[ 'pro' ] ) )
        {
            $pro = $_GET[ 'pro' ];
            if( $pro < 0 ) $pro = 0;
            if( $pro > 1 ) $pro = 1;
            
            $map = str_replace( "\"", "'", $_GET[ 'map' ] );
            
            printf( "<h3>%s %s15</h3>\n", $map, $pro ? "Pro" : "Nub" );
            print( "<table cellpadding=\"2\" cellspacing=\"0\">\n" );
            print( "<tr class=\"header\">\n" );
            print( "<th class=\"pos\">#</th>\n" );
            print( "<th class=\"name\">Name</th>\n" );
            print( "<th class=\"time\">Time</th>\n" );
            print( "<th class=\"cp\">Checkpoints</th>\n" );
            print( "<th class=\"gc\">GoChecks</th>\n" );
            print( "</tr>\n" );
            
            $sql_query = mysql_query( sprintf( "SELECT * FROM kz_%s15 WHERE map = \"%s\" ORDER BY time LIMIT 15;", $pro ? "pro" : "nub", $map ), $sql_conn );
            
            $pos = 1;
            
            while( ( $result = mysql_fetch_array( $sql_query ) ) )
            {
                printf( "<tr id=\"pos%d\"%s>\n", $pos, ( ( $pos % 2 ) == 1 ) ? "" : " class=\"alt\"" );
                printf( "<td class=\"pos\">%d</td>\n", $pos );
                printf( "<td class=\"name\">%s</td>\n", htmlspecialchars( $result[ 'name' ] ) );
                printf( "<td class=\"time\">%s</td>\n", time_to_string( $result[ 'time' ] ) );
                printf( "<td class=\"cp\">%d</td>\n", $result[ 'cp' ] );
                printf( "<td class=\"gc\">%d</td>\n", $result[ 'gc' ] );
                print( "</tr>\n" );
                
                $pos++;
            }
            
            while( $pos < 15 )
            {
                printf( "<tr id=\"pos%d\"%s>\n", $pos, ( ( $pos % 2 ) == 1 ) ? "" : " class=\"alt\"" );
                printf( "<td class=\"pos\">%d</td>\n", $pos );
                print( "<td class=\"name\"></td>\n" );
                print( "<td class=\"time\"></td>\n" );
                print( "<td class=\"cp\"></td>\n" );
                print( "<td class=\"gc\"></td>\n" );
                print( "</tr>\n" );
                
                $pos++;
            }
            
            print( "</table>\n" );
            
            printf( "<p><a href=\"top15.php?map=%s&pro=%d\">%s15</a> | <a href=\"top15.php\">Maps</a></p>\n", $map, ( 1 - $pro ), $pro ? "Nub" : "Pro" );
        }
        else
        {
            print( "<h3>All Maps</h3>\n" );
            print( "<table cellpadding=\"2\" cellspacing=\"0\">\n" );
            print( "<tr class=\"header\">\n" );
            print( "<th class=\"map\">Map</th>\n" );
            print( "<th class=\"toplink\">Pro15</th>\n" );
            print( "<th class=\"toplink\">Nub15</th>\n" );
            print( "</tr>\n" );
            
            $maps = array( );
            
            $sql_query = mysql_query( "SELECT map FROM kz_pro15 GROUP BY map ORDER BY map;", $sql_conn );
            
            while( ( $result = mysql_fetch_array( $sql_query ) ) )
            {
                $map = strtolower( $result[ 'map' ] );
                
                $maps[ $map ] = $map;
            }
            
            $sql_query = mysql_query( "SELECT map FROM kz_nub15 GROUP BY map ORDER BY map;", $sql_conn );
            
            while( ( $result = mysql_fetch_array( $sql_query ) ) )
            {
                $map = strtolower( $result[ 'map' ] );
                
                $maps[ $map ] = $map;
            }
            
            asort( $maps );
            
            $pos = 1;
            
            foreach( $maps as $map )
            {
                printf( "<tr%s>\n", ( ( $pos % 2 ) == 1 ) ? "" : " class=\"alt\"" );
                printf( "<td class=\"map\">%s</td>\n", $map );
                printf( "<td class=\"toplink\"><a href=\"top15.php?map=%s&pro=1\">-link-</a></td>\n", $map );
                printf( "<td class=\"toplink\"><a href=\"top15.php?map=%s&pro=0\">-link-</a></td>\n", $map );
                print( "</tr>\n" );
                
                $pos++;
            }
            
            print( "</table>\n" );
        }
        
        mysql_close( $sql_conn );
    }
    else
    {
        if( $sql_conn )
        {
            mysql_close( $sql_conn );
        }
        
        print( "<h3>Could not connect to database.</h3>\n" );
    }
    
    function time_to_string( $time )
    {
        if( $time < 0 )
        {
            $unknown_char = "?";
            
            $string = sprintf( "%s:%s%s.", $unknown_char, $unknown_char, $unknown_char );
            for( $i = 0; $i < TIME_DECIMAL_PLACES; $i++ )
            {
                $string .= $unknown_char;
            }
            
            return $string;
        }
        
        $time = round( $time, TIME_DECIMAL_PLACES );
        
        $minutes = floor( $time / 60 );
        $seconds = floor( $time - ( $minutes * 60 ) );
        $milliseconds = floor( ( $time - floor( $time ) ) * pow( 10, TIME_DECIMAL_PLACES ) );
        
        return sprintf( sprintf( "%%d:%%02d.%%0%dd", TIME_DECIMAL_PLACES ), $minutes, $seconds, $milliseconds );
    }
    
?>
</body>
</html>