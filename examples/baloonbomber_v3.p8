pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- baloon bomber
-- a sidescroller in parens-8

#include ../v3/parens8_field.lua
#include ../v3/builtin/def_builtin.lua
#include ../v3/builtin/operators.lua
#include ../v3/builtin/flow.lua
#include ../v3/builtin/env.lua
#include ../v3/builtin/table.lua
#include ../v3/builtin/seq.lua

parens8[[
(set gravity .4)
(set plane (table))

(set update_particles (fn ()
	(foreach particles (fn (particle) (env particle (seq
		(update particle)
		(set ttl (- ttl 1))
		(when (< ttl 0) (del particles particle))
		(when (or (~= x (mid x -8 135))
		          (~= y (mid y -8 135)))
			(del particles particle))))))))

(set draw_particles (fn () (seq
	(set particles_fg (table))
	(foreach particles (fn (particle)
		(when (not particle.fg)
			(particle.draw particle)
			(add particles_fg particle)))))))

(set draw_particles_fg (fn ()
	(for ((particle) (all particles_fg))
		(particle.draw particle))))

(set make_smoke (fn (arg_x arg_y) (add particles (table
	(x arg_x) (y arg_y) (r 2) (ttl 0x7fff)
	(update (fn (self) (env self (seq
		(set x (- (+ x (- (rnd 2) 1)) speed))
		(set y (- (+ y (- (rnd 2) 1)) .5))
		(set r (+ r .25))))))
	(draw (fn (self) (env self (circfill x y r 0))))
))))

(set explosion_colors (table 0 7 10 9 2 1))
(set make_explosion (fn (arg_x arg_y arg_r) (add particles (table
		(x arg_x) (y arg_y) (r arg_r) (ttl 10) (fg 1)
		(update (fn (self) (env self (when (< ttl 5) (seq
			(set x (- x speed))
			(make_smoke (- (+ x (rnd r)) (/ r 2))
			            (- (+ y (rnd r)) (/ r 2))))))))
		(draw (fn (self) (env self
			(circfill
			    x y
			    (* r (min (/ ttl 8) 1))
			    (or ([] explosion_colors (- 11 ttl)) 0)))))))))

(set make_pop (fn (x y) (add particles (table
		(x x) (y y) (ttl 3) (fg 1)
		(update (fn () (quote)))
		(draw (fn (self) (spr 10 self.x self.y)))))))

(set make_spark_cluster (fn (arg_x arg_y amount spread) (add particles (table
		(x arg_x) (y arg_y) (ttl 15) (fg 1)
		(sparks (let ((res (table))) (seq
			(while (> amount 0) (seq
			    (set amount (- amount 1))
			    (add res (table
			        (x arg_x) (y arg_y)
					(vx (- (rnd (* 2 spread)) spread))
					(vy (* -2 (rnd spread)))))))
			res)))
		(update (fn (self) (foreach self.sparks (fn (spark) (env spark (seq
		    (set vy (* .95 (+ vy gravity)))
		    (set vx (* .95 vx))
		    (set x (+ vx (- x (* speed (min (/ 8 self.ttl) 1)))))
		    (set y (+ vy y))))))))
		(draw (fn (self) (foreach self.sparks (fn (spark)
		    (pset spark.x spark.y 10)))))))))

(set plane.draw (fn (self) (env self (spr
	(when (> lives 0)
		(when (> vy 1) 2 (when (< vy -1) 4 0))
		(let ((osc (sin (/ t 60))))
			(when (> osc .66) 2 (when (< osc -.66) 4 0))))
	x (- y 4) 2 2))))

(set plane.update (fn (self) (env self (seq
	(when (> lives 0)
		(seq
			(set vx (+ vx (when (btn 0) -1 (when (btn 1) 1 0))))
			(set vy (+ vy (when (btn 2) -1 (when (btn 3) 1 0)))))
		(set vy 1))

	(set vy (* .8 (+ vy (/ (sin(/ t 30)) 10))))
	(set vx (* .8 vx))

	(set x (+ x vx))
	(set y (+ y vy))
	(when (> lives 0)
		(let ((clx (mid x 0 (- 127 width)))
		      (cly (mid y 0 (- 127 height)))) (seq
			(when (~= clx x) (set vx 0))
			(when (~= cly y) (set vy 0))
			(set x clx)
			(set y cly))))

	(when (btnp 4) (set lives (% (- lives 1) 4)))

	(when (< lives 2) (seq
		(let ((i 0)) (while (< i speed) (seq
			(make_smoke (- (+ x 8) (/ (* i (+ vx speed)) speed))
			            (- (+ y 4) (/ (* i vy) speed)))
			(set i (+ i 1.5)))))
		(when (and (< lives 1) (< (rnd 6) 1))
			(make_explosion (+ x (rnd 16)) (+ y (rnd 8)) (+ 2 (rnd 4))))))
	))))

(set for_outline (fn (f) (seq
	(f -1 -1) (f 0 -1) (f 1 -1)
	(f -1 0)           (f 1 0)
	(f -1 1)  (f 0 1)  (f 1 1))))

(set print_outlined (fn (s x y col ol) (seq
	(for_outline (fn (ox oy) (print s (+ x ox) (+ y oy) ol)))
	(print s x y col))))

(set display_hud (fn () (seq
	(print_outlined t 2 2 7 4)
	(let ((str (tostring (# particles))))
		(print_outlined str (- 127 (* 4 (# str))) 121 7 4))
	(let ((i 0)) (while (< i 3) (seq
		(spr (when (< i plane.lives) 14 15) (+ 104 (* i 8)) 1)
		(set i (+ i 1)))))
	(print_outlined (stat 1) 2 121 7 4)
	(print_outlined (stat 0) 2 113 7 4)
)))

(set clouds_bg (table))
(set clouds_fg (table))

(set make_cloud (fn (x y r) (table
	(x (* x 8)) (y (+ y (rnd 8))) (r (+ r (rnd 8))))))

(set init_clouds (fn () (let ((i 0)) (while (< i 18) (seq
	(add clouds_bg (make_cloud i 0 6))
	(add clouds_bg (make_cloud i 120 6))
	(add clouds_fg (make_cloud i -4 4))
	(add clouds_fg (make_cloud i 124 4))
	(set i (+ i 1)))))))

(set update_clouds (fn (clouds topy boty rad spd)
                       (foreach clouds (fn (cloud) (env cloud (seq
	(set x (- x spd))
	(when (< x -7) (seq
		(set x (+ spd (% x 144)))
		(set y (+ (rnd 8) (when (< y 64) topy boty)))
		(set r (+ rad (rnd 8)))))))))))

(set draw_sky (fn () (seq
	(foreach clouds_bg (fn (cloud) (env cloud
		(circfill x y r 15))))
	(foreach clouds_fg (fn (cloud) (env cloud
		(circfill x y r 7)))))))

(set collides (fn (a b)
	(and (and (< a.x (+ b.x b.width))
	          (< b.x (+ a.x a.width)))
	     (and (< a.y (+ b.y b.height))
	          (< b.y (+ a.y a.height))))))

(set distance2 (fn (a b) (+
	(^ (- a.x b.x) 2)
	(^ (- a.y b.y) 2))))

(set bombs (table))

(set make_bomb (fn (arg_x arg_y) (add bombs (table
	(x arg_x) (y arg_y) (width 6) (height 6) (baloon 1) (blink 0)
	(update (fn (self) (env self (let ((inrange (< (distance2 self plane) 512))) (seq
				(when (or (< x -8) (> y 136)) (del bombs self))
				(set x (- x speed))
				(when (not self.baloon)
					(seq (set vy (* .9 (+ vy gravity)))
					     (set y (+ y vy)))
					(when (and inrange
					           (collides plane (table
					                (x x) (y (- y 10)) (width 8) (height 8))))
					      (seq (make_pop (- x 1) (- y 10))
					           (set baloon (quote))
					           (set vy 0))))
				(when (and inrange (collides self plane))
					(seq (make_explosion (+ x 3) (+ y 3) 8)
					     (make_spark_cluster (+ x 3) (+ y 3) 8 2)
					     (set plane.lives (- plane.lives 1))
					     (del bombs self))
					(set blink (when inrange (+ blink 0.2) .5))))))))
	(draw (fn (self) (env self (let ((sprnum (when (> (sin blink) .7) 24 8))) (seq
				(when self.baloon (spr 26 (- x 1) (- y 10))
				                  (set sprnum (+ sprnum 1)))
				(spr sprnum (- x 1) (- y 2)))))))))))

(set _init (fn () (seq
	(set plane.x 56)
	(set plane.y 60)
	(set plane.vx 0)
	(set plane.vy 0)
	(set plane.width 16)
	(set plane.height 8)
	(set plane.lives 2)
	(set t 0)
	(set score 0)
	(set speed 2)
	(set particles (table))
	(set bombs (table))
	(init_clouds))))

(set _update (fn () (seq
	(when (== 0 (% t (flr (/ 30 speed)))) (make_bomb 130 (rnd 122)))
	(set speed (+ speed .001))
	(update_clouds clouds_bg 0 120 6 (* speed .5))
	(update_clouds clouds_fg -4 124 4 (* speed .75))
	(update_particles)
	(plane.update plane)
	(foreach bombs (fn (bomb) (bomb.update bomb)))
	(set t (+ t 1)))))

(set _draw (fn () (seq
	(cls 12)
	(draw_sky)
	(draw_particles)
	(foreach bombs (fn (bomb) (bomb.draw bomb)))
	(plane.draw plane)
	(draw_particles_fg)
	(display_hud))))
]]

__gfx__
00000000000000000000000000000000000000000000000000000000000000000040040000000000000000000000000000000000000000000990990009909900
00000000000000000000000000000000000000000000000000000007777000000040f4000000f000070000700000000000000000000000009aa9aa9092292290
00000000000000000000009eeeee0000000000888888000000000077777700000046640000066000007007000000000000000000000000009a999a9092222290
00000000000000000000009eeeeee000000000222288800000000077777777700055550000555500000000000000000000000000000000004944494042222240
000000888888e0040000004888888004000000444444400400000777777777770555555005555550000000000000000000000000000000000494940004222400
88800002228880040000008888888004000000229229200400007777777777770155551001555510007007000000000000000000000000000049400000424000
8a9800009009767488840048888886748884002882288674007777ff77ff777f0011110000111100070000700000000000000000000000000004000000040000
89a888888008856789988848888885678888888888888567fffffffffffffff00001100000011000000000000000000000000000000000000000000000000000
088888888888811408888822228801140ff888844444411400000000000000000040040000000000007777000000000000000000000000000000000000000000
0ff00004444440040000000444444004000000044f7f400400000000000000000040f4000000f000077777700000000000000000000000000000000000000000
000000000f7f00040000000000f000040000000000f0000400000000000000000046640000066000ff7777ff0000000000000000000000000000000000000000
0000000000f000000000000000000000000000000000000000000000077770000088880000888800444444440000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000777777000888888008888880744f7f4f0000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000007700777777770002888820028888204ff4f4f40000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000007777777ff777f000022220000222200044444400000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000fffffffffffff000000220000002200004ffff400000000000000000000000000000000000000000
0aaaaa000aaaaa00aa000aa00aaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a99999a0a99999a099a0a990a9999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9900000099000990999a999099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9900aaa0990009909949499099aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9900099099aaa9909904099099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49999940994449909900099049999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04444400440004404400044004444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aaaaa00aa000aa00aaaaaa0aaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a99999a099000990a9999990999999a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99000990990009909900000099000990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
990009909900099099aa000099000940000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99000990499099409900000099aaa900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49999940049994004999999099444990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04444400004440000444444044000440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
7777777777777777777777777777777777777777777777777777777777777777777777777777777777777777ff77777777777777777777777777777777777777
744444444444447777777777777777777777777777777777777777777777777777777777777777777777777ffff7777777777777799799777997997779979977
74777477747774777777777777777777777777777777777777777777f77777777777777777777777777777fffff77777777777779aa9aa979229229792292297
74744444747474777777777777777777777777777777777777777777fffff7777777777777777777fffffffffff77777777777779a999a979222229792222297
7477744774777477777777777777777777777777777777777777777ffffff77777777777777777fffffffffffff7777777777777494449474222224742222247
744474447444747777777777777777f777777777777777777777777fffffff77777777777ffffffffffffffffff7777777777777749494777422247774222477
7477747774747477777777777777fffff77777fff77777ffff777ffffffffff777777777ffffffffffffffffffff77777777777777494f7777424777774247ff
7444444444744477777777777777fffffffffffffffffffffffffffffffffffff77777ffffffffffffffffffffff7777777777777774fff777747777fff4ffff
77777777777777777777777777fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7777777777777fffffff77777ffffffffff
7777777777777777777777777fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff77777777777fffffffffffffffffffffff
77777777777fffff7777777ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff777777777ffffffffffffffffffffffff
7777777777fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff77777ffffffffffffffffffffffffff
777777777ffffffffffcccffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
7777777fffffffffffcccccfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fccccccccfffffffcccccccccfffffffcffffffffffffffffffffffffffffffffffffffffffffffffffffccccffffffffffffffffffffcffffffffffffffffff
ccccccccccccccccccccccccccccccccccccccccccfffffffffffffffffcfffffffffffffffffffffffccccccccccfffffffffffffffcccccfffffffcccfffff
cccccccccccccccccccccccccccccccccccccccccccccccfffffffffffccccffffffffffffffffffffcccccccccccccfffffffffffccccccccccccccccccffff
cccccccccccccccccccccccccccccccccccccccccccccccccfffffffcccccccfffffffffffffffffcccccccccccccccccfffffffcccccccccccccccccccccfff
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccfffffffccccccccccccccccccccccccccccccccccccccccccccccccccccccff
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc7777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccc777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccff7777ffccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc44444444ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc744f7f4fccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc4ff4f4f4ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccc444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccc4ffff4cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc4cc4ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc4cf4ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccc00000ccccccccccccccccccccccccc4664ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccc0000000000000cccccccccccccccccc8888ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccc000000000000000000ccccccccccccc888888cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccc00000000000000000000cccccccccccc288882cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccc000000000000000000000cccccccccccc2222ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccc0000000000000000000000cccccccccccc22cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccc0000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccc00000000000000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccc000000000000000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccc000000000000000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccc0000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccc0000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccc000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccc0000000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccc000000000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccc000000000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccc0000000000000000000000000000000000c000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccc0000000000000000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccc0000000000000000000000000000000000000000000cc000ccc000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00ccccccccccc00000000000000000000000c0000000000000000000000000c00000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0000cccccccc0000000000000000000000ccccc0000000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
000000cccc00000000000000000000ccccccccc00000000000000000000000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0000000cc000000000000000000000ccccccccccc0000000000000000000000000000000ccc000cccccccccccccccccccccccccccccccccccccccccccccccccc
0000000c00000000000000000000000cccccccccccccc0000000000000000000000000000000000ccccccccccccccccccccccccccccccccccccccccccccccccc
0000000000000000000000000000000ccccccccccccccc000c000000cc000c00000000000000000c00000cccccc888888ecc4ccccccccccccccccccccccccccc
00000000000000000000000000000000ccccccccccccccccccc000ccccccccc0000000000000000000000888000c222888cc4ccccccccccccccccccccccccccc
00000000000000000000000000000000ccccccccccccccccccccccccccccccccccc00000000000c0000008a98000090c97674ccccccccccccccccccccccccccc
00000000000000000000000000000000ccccccccccccccccccccccccccccccccccccccccc000ccc00000089a8888880088567ccccccccccccccccccccccccccc
00000000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccc000000888888888888114ccccccccccccccccccccccccccc
00000000000000000000000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccff0000444444cc4ccccccccccccccccccccccccccc
0000000000000000000000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00f7fccc4ccccccccccccccccccccccccccc
0000000000000000000000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccfcccccccccccccccccccccccccccccccc
000000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00000000000000000000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
000000000000000000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
000000000000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0000000000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0000000000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0000000000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0000000000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00000000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
000cc00000000000cccccccccccccccccccccccccc7777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00cccc000000000cccccccccccccccccccccccccc777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00cccccc00000cccccccccccccccccccccccccccff7777ffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccc44444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc744f7f4fcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc4ff4f4f4cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccc444444ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccc4ffff4ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc4cc4cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc4cf4cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc4664cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc5555cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccc555555ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccc155551ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc1111cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc11ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777ccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccff7777ffccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc44444444cccccccccccccccccccccc7777fffffcccccccccccccccc
cccccccccccc7777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc744f7f4fccccccccccccccccccccc777777ffffffcccccccccccccc
ccccccccccc777777cccccccccccccccccccccccccccccccccccccccccccccccccccccccc4ff4f4f4ccccccccccccccccccccff7777fffffffffcccccccccccc
ccccccccccff7777ffccccccccfffffccccccccccccccccccccccccccfffffffcccccccccc444444cccccccccccccccccffff44444444ffffffffccccccccccc
cccccccccc44444444ccccccfffffffffccccccccccccccccccccccfffffffffffcccccccf4ffff4cccccccccccccccffffff744f7f4ffffffffffcccccccccc
fccccccccc744f7f4ffffffffffffffffffccccccccccccccccccffffffffffffffffffffff4ff4ffffcccccccccccfffffff4ff4f4f4ffffffffffccccccccc
ffcccccccc4ff4f4f4ffffffffffffffffffccccccccccccccccfffffffffffffffffffffff4ff4fffffffffcccccfffffffff444444ffffffffffffccfffffc
fffcccccccc444444ffffffffffffffffffffffccfffffffcffffffffffffffffffffffffff4664fffffffffffccffffffffff4ffff4ffffffffffffffffffff
ffffccccccc4ffff4ffffffffffffffffffffffffffffffff77777fffffffffffffffffffff5555ffffffffffffffffffffffff4f74777ffffffffffffffffff
ffffcccccccc4cf4fffffffffffffffffffffffffffffff777777777fffffffffffffffff7555555fffffffffffffffffffffff47f477777ffffffffffffffff
fffffcccccff4ff4ffffffffffffffffffffffffffffff77777777777ffffffffffffff777155551fffffffffffffffff7777774664777777ffffffffffffff7
fffffcccffff4664fffffffffffffffffffffffff77777777777777777ffffffffffff7777711117777777fffffffff7777777755557777777ffffffffffff77
f44444fff4444444444444fffffffffffffffff77777777777777777777fffff777777777777117777777777ff777f777777775555557777777fff444f444477
f47774fff4777477747774fffffffffff77777777777777777777777777fff77777777777777777777777777777777777777771555517777777fff4747477477
f44474fff47444447474447ffffffff77777777777777777777777777777f7777777777777777777777777777777777777777771111777777777ff4744447477
f47774fff47774477477747fffffff77777777777777777777777777777777777777777777777777777777777777777777777777117777777777774777447477
747444444444744474447477ff777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777774747447447
74777447447774777477747777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777774777477747
74444444444444444444447777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777774444444447
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777

