class PlanParser

token ident fuel_amount fuel_rate fuel_used str deg rad number sm nmi km ft meter mph kts kph fps mps cf to 

rule

plan: # nil
    | statement ';' plan
    ;

statement: fromviato checkpoint 
         { add_waypoint Waypoint::Checkpoint.new(val[1]) }

         | fromviato checkpoint radial checkpoint radial comment 
         { add_waypoint Waypoint::Intersection.new(*val[1..5]) }

         | fromviato checkpoint dir '/' dist comment
         { add_waypoint Waypoint::RNAV.new(val[1], val[2], val[4], val[5]) }

         # flattened due to shift/reduce conflict
         | 'from' latlon comment
         { add_waypoint Waypoint::Waypoint.new(*val[1..2]) }
         | 'via' latlon comment
         { add_waypoint Waypoint::Waypoint.new(*val[1..2]) }
         | 'to' latlon comment
         { add_waypoint Waypoint::Waypoint.new(*val[1..2]) }

         | 'via' dist comment
         { add_waypoint Waypoint::Incremental.new(*val[1..2]) }
         | 'to' dist comment
         { add_waypoint Waypoint::Incremental.new(*val[1..2]) }

         | climb alt climb_rate
         { add_waypoint Waypoint::Climb.new(*val[1..2]) }

         | descend alt climb_rate
         { add_waypoint Waypoint::Descend.new(*val[1..2]) }

         | fuel_amount fuel_qty
         { @leg.fuel_amount = val[1] }

         | fuel_rate fuel_qty
         { @leg.fuel_rate = val[1] / 'hour' }

         | fuel_used fuel_qty
         { @leg.fuel_used = val[1] }

         | 'alt' alt
         { @leg.alt = @alt = val[1] }

         | 'comment' str
         { @leg.comment = val[1] }

         | 'nav' number vor
         { @leg.nav[val[1]-1] = val[2] }

         | 'ias' speed
         { @leg.ias = val[1] }

         | 'tas' speed
         { @leg.tas = val[1] }

         | 'temp' temp
         { @leg.temp = val[1] }

         | 'wind' dir '@' speed
         { @leg.wind = [val[1], val[3]] }

         | 'wind' 'calm'
         { @leg.wind = nil }
         ;

vor: checkpoint { error "Expected a VOR" unless VOR === val[0] }
   ;

checkpoint: ident 
          { 
            coord = @leg.coord unless @leg.nil?
            result = Aviation::Checkpoint.closest(coord, val[0].upcase)
          }
          ;

fromviato: 'from' 
   { 
     @plan = Plan.new
     @pf.push @plan
   }
   | 'via' | 'to'
   ;

radial: dir
      ;

dir: number deg { result = val[0].rad }
   | number rad
   | number { result = val[0].rad }
   ;


comment:
       | str { result = val[0][1..-2] }
       ;

dist: number            { result = 'nmi'.u * val[0] }
    | number dist_unit  { result = val[1] * val[0] }
    ;

dist_unit: sm | nmi | km | ft | meter
         ;

speed: number            { result = 'kts'.u * val[0] }
     | number speed_unit { result = val[1] * val[0] }
     ;

speed_unit: mph|kts|kph|fps|mps
          ;

latlon: lat lon { result = [val[0], val[1]].coord }
      ;

lat: ordinate north
   | ordinate south { result = -val[0] }
   ;

lon: ordinate east
   | ordinate west  { result = -val[0] }
   ;


ordinate: number 		{ result = val[0].rad }
        | number rad
        | number deg            { result = val[0].rad }
        | number deg number "'" { result = [val[0], val[2]].rad }
        | number deg number "'" number '\"' 
	{ result = [val[0], val[2], val[4]].rad }
        ;

north: 'n' | 'N'
     ;

south: 's' | 'S'
     ;

east: 'e' | 'E'
    ;

west: 'w' | 'W'
    ;

alt: number             { result = 'ft'.u * val[0] }
   | number dist_unit   { result = val[1] * val[0] }
   ;

fuel_qty: number { result = 'gallon'.u * val[0] }
        ;

temp: number            { result = 'tempC'.u * val[0] }
    | number deg        { result = 'tempC'.u * val[0] }
    | number deg cf     { result = val[1] * val[0] }
    | number cf         { result = val[1] * val[0] }
    ;

climb: 'climb' | 'up'
     ;
descend: 'descend' | 'desc' | 'down'
     ;
climb_rate: number              { result = 'ft/min'.u * val[0] }
          | number speed_unit   { result = val[1] * val[0] }
          ;
