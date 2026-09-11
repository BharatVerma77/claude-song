on run argv
  set msg to item 1 of argv
  set ttl to item 2 of argv
  set secs to (item 3 of argv) as integer
  tell me to activate
  display dialog msg with title ttl buttons {"Stop music"} default button 1 with icon note giving up after secs
end run
