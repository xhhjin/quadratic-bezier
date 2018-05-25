/* 
 * Quadratic bezier through three points
 *
 * By xhhjin,		http://xuhehuan.com
 * 
 */

(function() {

	var canvas, ctx, point, style, drag = null, dPoint;

	// define initial points
	function Init() {
		point = {
			p1: { x:200, y:350 },
			p2: { x:600, y:350 }
		};
		point.cp1 = { x: 500, y: 200 };
		
		// default styles
		style = {
			curve:	{ width: 2, color: "#333" },
			cpline:	{ width: 1, color: "#C00" },
			curve1:	{ width: 1, color: "#00F" },
			curve2: { width: 1, color: "#0F0" },
			point: { radius: 10, width: 2, color: "#900", fill: "rgba(200,200,200,0.5)", arc1: 0, arc2: 2 * Math.PI }
		}
		
		// line style defaults
		ctx.lineCap = "round";
		ctx.lineJoin = "round";

		// event handlers
		canvas.onmousedown = DragStart;
		canvas.onmousemove = Dragging;
		canvas.onmouseup = canvas.onmouseout = DragEnd;
		
		DrawCanvas();
	}
	
	
	// draw canvas
	function DrawCanvas() {
		ctx.clearRect(0, 0, canvas.width, canvas.height);
		
		// control lines
		ctx.lineWidth = style.cpline.width;
		ctx.strokeStyle = style.cpline.color;
		ctx.beginPath();
		ctx.moveTo(point.p1.x, point.p1.y);
		ctx.lineTo(point.cp1.x, point.cp1.y);
		ctx.lineTo(point.p2.x, point.p2.y);
		ctx.stroke();
		
		// curve
		ctx.lineWidth = style.curve.width;
		ctx.strokeStyle = style.curve.color;
		ctx.beginPath();
		ctx.moveTo(point.p1.x, point.p1.y);
		
		through = !document.getElementById("cbThrough").checked;
		if(through)
		{
			tmpx1 = point.p1.x-point.cp1.x;
			tmpx2 = point.p2.x-point.cp1.x;
			tmpy1 = point.p1.y-point.cp1.y;
			tmpy2 = point.p2.y-point.cp1.y;
			dist1 = Math.sqrt(tmpx1*tmpx1+tmpy1*tmpy1);
			dist2 = Math.sqrt(tmpx2*tmpx2+tmpy2*tmpy2);
			tmpx = point.cp1.x-Math.sqrt(dist1*dist2)*(tmpx1/dist1+tmpx2/dist2)/2;
			tmpy = point.cp1.y-Math.sqrt(dist1*dist2)*(tmpy1/dist1+tmpy2/dist2)/2;
			ctx.quadraticCurveTo(tmpx, tmpy, point.p2.x, point.p2.y);
		}
		else
		{
			ctx.quadraticCurveTo(point.cp1.x, point.cp1.y, point.p2.x, point.p2.y);
		}
		
		ctx.stroke();
		
		//new, t range is [0, 1]
		ctx.beginPath();
		ctx.lineWidth = style.curve1.width;
		ctx.strokeStyle = style.curve1.color;
		
		ctx.moveTo(point.p1.x, point.p1.y);
		
		tmpx1 = point.cp1.x-point.p1.x;
		tmpx2 = point.p2.x-point.cp1.x;
		tmpx3 = point.p2.x-point.p1.x;
		tmpy1 = point.cp1.y-point.p1.y;
		tmpy2 = point.p2.y-point.cp1.y;
		tmpy3 = point.p2.y-point.p1.y;
		//dist1 = Math.sqrt(tmpx1*tmpx1+tmpy1*tmpy1);
		//dist2 = Math.sqrt(tmpx2*tmpx2+tmpy2*tmpy2);
		dist1 = Math.sqrt(Math.sqrt(tmpx1*tmpx1+tmpy1*tmpy1));
		dist2 = Math.sqrt(Math.sqrt(tmpx2*tmpx2+tmpy2*tmpy2));
		var t1 = dist1/(dist1+dist2);	//0.5  dist1/(dist1+dist2)
		var fAX = point.p1.x;
		var fBX = (tmpx1-t1*t1*tmpx3)/(t1-t1*t1);
		var fCX = tmpx3-fBX;
		var fAY = point.p1.y;
		var fBY = (tmpy1-t1*t1*tmpy3)/(t1-t1*t1);
		var fCY = tmpy3-fBY;
		var step = 0.01
		for(var i = 0; i < (1+step); i+=step) {
			// 计算两个动点的坐标
			var t = i;
			var bx  = fAX + fBX * t + fCX * t * t;
			var by  = fAY + fBY * t + fCY * t * t;
			
			ctx.lineTo(bx, by);
		}
		ctx.stroke();
		
		//new2, t range is extended to [-1, 2]
		ctx.beginPath();
		ctx.lineWidth = style.curve2.width;
		ctx.strokeStyle = style.curve2.color;
		
		tmpx1 = point.cp1.x-point.p1.x;
		tmpx2 = point.p2.x-point.cp1.x;
		tmpx3 = point.p2.x-point.p1.x;
		tmpy1 = point.cp1.y-point.p1.y;
		tmpy2 = point.p2.y-point.cp1.y;
		tmpy3 = point.p2.y-point.p1.y;
		dist1 = Math.sqrt(Math.sqrt(tmpx1*tmpx1+tmpy1*tmpy1));
		dist2 = Math.sqrt(Math.sqrt(tmpx2*tmpx2+tmpy2*tmpy2));
		t1 = dist1/(dist1+dist2);
		fCX = (9*tmpx1-9*t1*tmpx3)/(t1*t1-t1);
		fBX = 3*tmpx3-fCX;
		fAX = point.p1.x-fBX/3-fCX/9;
		fCY = (9*tmpy1-9*t1*tmpy3)/(t1*t1-t1);
		fBY = 3*tmpy3-fCY;
		fAY = point.p1.y-fBY/3-fCY/9;
		step = 0.01;
		var a = -0.5;	// No less than -1
		var b = 1.5;	// No more than 2
		for(i = a; i < (b+step); i+=step) {
			var t = (i+1)/3;	// i-(-1)/(2-(-1))
			var bx  = fAX + fBX * t + fCX * t * t;
			var by  = fAY + fBY * t + fCY * t * t;
			
			if(i==a)
				ctx.moveTo(bx, by);
			else
				ctx.lineTo(bx, by);
		}
		ctx.stroke();

		// control points
		for (var p in point) {
			ctx.lineWidth = style.point.width;
			ctx.strokeStyle = style.point.color;
			ctx.fillStyle = style.point.fill;
			ctx.beginPath();
			ctx.arc(point[p].x, point[p].y, style.point.radius, style.point.arc1, style.point.arc2, true);
			ctx.fill();
			ctx.stroke();
		}
	}
	
	// start dragging
	function DragStart(e) {
		e = MousePos(e);
		var dx, dy;
		for (var p in point) {
			dx = point[p].x - e.x;
			dy = point[p].y - e.y;
			if ((dx * dx) + (dy * dy) < style.point.radius * style.point.radius) {
				drag = p;
				dPoint = e;
				canvas.style.cursor = "move";
				return;
			}
		}
	}
	
	
	// dragging
	function Dragging(e) {
		if (drag) {
			e = MousePos(e);
			point[drag].x += e.x - dPoint.x;
			point[drag].y += e.y - dPoint.y;
			dPoint = e;
			DrawCanvas();
		}
	}
	
	
	// end dragging
	function DragEnd(e) {
		drag = null;
		canvas.style.cursor = "default";
		DrawCanvas();
	}

	
	// event parser
	function MousePos(event) {
		event = (event ? event : window.event);
		return {
			x: event.pageX - canvas.offsetLeft,
			y: event.pageY - canvas.offsetTop
		}
	}
	
	
	// start
	canvas = document.getElementById("canvas");
	if (canvas.getContext) {
		ctx = canvas.getContext("2d");
		Init();
	}
	
})();

 



