class PlanParser
rule
plan: 
    | statement ';' plan
    ;
statement: fvt ident
         | fvt ident radial ident radial ncc
         | fvt ident dir '/' dist ncc
         | fvt lat lon ncc
         | 'via' dist ncc
         | 'climb' alt climb_rate
         | descend alt climb_rate
         | fuel_amount fuel_qty
         | fuel_rate fuel_rate
         | fuel_used fuel_qty
         | 'alt' alt
         | 'comment' str
         | 'nav' number ident
         | 'ias' speed
         | 'tas' speed
         | 'temp' temp
         | 'wind' dir '@' speed
         ;

radial: dir
      ;
dir: number deg { result = val[0].rad }
   | number rad
   | number
   ;
ncc: 
   | name { result = [val[0],nil,nil] }
   | name city { result = [val[0],val[1],nil] }
   | name city comment { result = val }
   ;
name: str
    ;
city: str
    ;
comment: str
       ;
dist: number 
    | number dist_unit
    ;
dist_unit: sm | nm | km | ft | meter
         ;
speed: number
     | number speed_unit
     ;
speed_unit: mph|kts|kph|fps|mps
          ;
lat: ordinate ns
   ;
lon: ordinate ew
   ;
ordinate: number rad
        | number deg
        | number deg number "'"
        | number deg number "'" number '\"'
        ;
alt: number
   | number dist_unit
   ;
fuel_qty: number
        ;
fuel_rate: number
         ;
temp: number 
    | number deg
    | number deg cf
    | number cf
    ;

