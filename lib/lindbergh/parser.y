class PlanParser

token ident descend fuel_amount fuel_rate fuel_used str deg rad number sm nmi km ft meter mph kts kph fps mps cf to

rule

plan: # nil
    | statement ';' plan
    ;

statement: fromviato checkpoint 
         { add_waypoint Waypoint::Checkpoint.new(val[1]) }

         | fromviato checkpoint radial checkpoint radial ncc 
         { add_waypoint Waypoint::Intersection.new(*val[1..5]) }

         | fromviato checkpoint dir '/' dist ncc
         { add_waypoint Waypoint::RNAV.new(val[1], val[2], val[4], val[5]) }

         # flattened due to shift/reduce conflict
         | 'from' latlon ncc
         { add_waypoint Waypoint::Waypoint.new(*val[1..2]) }
         | 'via' latlon ncc
         { add_waypoint Waypoint::Waypoint.new(*val[1..2]) }
         | 'to' latlon ncc
         { add_waypoint Waypoint::Waypoint.new(*val[1..2]) }

         | 'via' dist ncc
         { add_waypoint Waypoint::Incremental.new(*val[1..2]) }
         | 'to' dist ncc
         { add_waypoint Waypoint::Incremental.new(*val[1..2]) }

         | 'climb' alt climb_rate
         { add_waypoint Waypoint::Climb.new(*val[1..2]) }

         | descend alt climb_rate
         { add_waypoint Waypoint::Descend.new(*val[1..2]) }

         | fuel_amount fuel_qty
         { @leg.fuel_amount = val[1] }

         | fuel_rate number
         { @leg.fuel_rate = val[1] }

         | fuel_used fuel_qty
         { @leg.fuel_used = val[1] }

         | 'alt' alt
         { @leg.alt = val[1] }

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
         { @leg.temp = [val[1], val[2]] }
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
     @pf.plans.push @plan
   }
   | 'via' | 'to'
   ;

radial: dir
      ;

dir: number deg { result = val[0].rad }
   | number rad
   | number
   ;

ncc: 
   | name               { result = [val[0],nil,nil] }
   | name city          { result = [val[0],val[1],nil] }
   | name city comment  { result = val[0..2] }
   ;

name: str
    ;

city: str
    ;

comment: str
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

latlon: lat ',' lon { result = [val[0], val[1]].coord }
      ;

lat: ordinate
   | ordinate north
   | ordinate south { result = -val[0] }
   ;

lon: ordinate
   | ordinate east
   | ordinate west  { result = -val[0] }
   ;


ordinate: number
        | number rad
        | number deg                            { val[0,1].rad }
        | number deg number "'"                 { [val[0], val[2]].rad }
        | number deg number "'" number '\"'     { [val[0], val[2], val[4]].rad }
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

fuel_qty: number
        ;

temp: number            { result = 'tempC'.u * val[0] }
    | number deg        { result = 'tempC'.u * val[0] }
    | number deg cf     { result = val[1] * val[0] }
    | number cf         { result = val[1] * val[0] }
    ;

climb_rate: number              { result = 'ft/sec'.u * val[0] }
          | number speed_unit   { result = val[1] * val[0] }
          ;
