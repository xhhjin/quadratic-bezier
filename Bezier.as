/**
* Bezier class for collision detection
* @author Olivier Besson (http://www.gludion.com)
* @version 0.2
*/

import flash.geom.Point;


class Bezier
{
	// a value we consider "small enough" to equal it to zero:
	// (this is used for double solutions in 2nd or 3d degree equation)
	public static var zeroMax:Number = 0.0000001;
	
	private var p0:Point;			// handle 0 of curve
	private var p1:Point;			// handle 1 of curve
	private var p2:Point;			// handle 2 of curve
	
	// bounds data
	private var xMin:Number;
	private var xMax:Number;
	private var yMin:Number;
	private var yMax:Number;
	
	// data for position+tangent
	private var pos:Point;			// generic position on curve
	private var tan:Point;			// tangent
	private var nor:Point;			// normal
	
	// PERSONAL note: for conversion quadratic=>cubic, put 2 handles at 2/3 of p0p1 and p2p1

	
	// data for nearest:
	private var A:Point;				// an util vector (= p1-p0)
	private var B:Point;				// an util vector (= p2-p1-A)
	private var solution:Object;		// solution of 3d degree equation
	private var nearest:Object;			// data about nearest point
	private var posMin:Point;			// nearest position on curve
	
	
	// defines a Quadratic Bezier Curve with p0 = (x0, y0), p1 = (x1, y1), p2 = (x2, y2)
	// p0 and p2 are anchor points.
	// p1 is control point.
	public function Bezier(x0,y0,x1,y1,x2,y2)
	{
		p0 = new Point();
		p1 = new Point();
		p2 = new Point();
	
		pos = new Point();
		tan = new Point();
		nor = new Point();
		
		A = new Point();
		B = new Point();
		solution = new Object();
		nearest = new Object();
		posMin = new Point();
		
		update(x0, y0, x1, y1, x2, y2);
	}
	
	// should be called after any anchor or control point is moved.
	public function update(x0, y0, x1, y1, x2, y2):Void
	{
		p0.x = x0;
		p0.y = y0;
		p1.x = x1;
		p1.y = y1;
		p2.x = x2;
		p2.y = y2;
		
		// precompute A and B, which will be very useful next.
		A.x = p1.x - p0.x;
		A.y = p1.y - p0.y;
		B.x = p0.x - 2 * p1.x + p2.x;
		B.y = p0.y - 2 * p1.y + p2.y;
		
		// rough evaluation of bounds:
		xMin = Math.min(x0, Math.min(x1, x2));
		xMax = Math.max(x0, Math.max(x1, x2));
		yMin = Math.min(y0, Math.min(y1, y2));
		yMax = Math.max(y0, Math.max(y1, y2));
		
		// more accurate evaluation:
		// see Andree Michelle for a faster but less readable method 
		var u:Number;
		if (xMin == x1 || xMax == x1) 
		{
			u = -A.x / B.x; // u where getTan(u).x == 0
			u = (1 - u) * (1 - u) * p0.x + 2 * u * (1 - u) * p1.x + u * u * p2.x;
			if (xMin == x1) xMin = u;
			else xMax = u;
		}
		if (yMin == y1 || yMax == y1) 
		{
			u = -A.y / B.y; // u where getTan(u).y == 0
			u = (1 - u) * (1 - u) * p0.y + 2 * u * (1 - u) * p1.y + u * u * p2.y;
			if (yMin == y1) yMin = u;
			else yMax = u;
		}
	}
	
	public function hitTest(pBounds:Object):Boolean
	{
		if (pBounds.xMax < xMin || pBounds.xMin > xMax) return false;
		if (pBounds.yMax < yMin || pBounds.yMin > yMax) return false;
		return true;
	}
	
	// returns { t:Number, pos:Point, dist:Number, nor:Point }
	// (costs about 80 multiplications+additions)
	public function findNearestPoint(x:Number, y:Number):Object
	{
		// a temporary util vect = p0 - (x,y)
		pos.x = p0.x - x;
		pos.y = p0.y - y;
		// search points P of bezier curve with PM.(dP / dt) = 0
		// a calculus leads to a 3d degree equation :
		var a:Number = B.x * B.x + B.y * B.y;
		var b:Number = 3 * (A.x * B.x + A.y * B.y);
		var c:Number = 2 * (A.x * A.x + A.y * A.y) + pos.x * B.x + pos.y * B.y;
		var d:Number = pos.x * A.x + pos.y * A.y;
		var sol:Object = thirdDegreeEquation(a, b, c, d);
		
		var t:Number;
		var dist:Number;
		var tMin:Number;
		var distMin:Number = Number.MAX_VALUE;
		var d0:Number = getDist(x, y, p0.x, p0.y);
		var d2:Number = getDist(x, y, p2.x, p2.y);
		var orientedDist:Number;
		
		if (sol != null)
		{
			// find the closest point:
			for (var i = 1; i <= sol.count; i++)
			{
				t = sol["s" + i];
				if (t >= 0 && t <= 1)
				{
					pos = getPos(t);
					dist = getDist(x, y, pos.x, pos.y);
					if (dist < distMin)
					{
						// minimum found!
						tMin = t;
						distMin = dist;
						posMin.x = pos.x;
						posMin.y = pos.y;
					}
				}
			}
			if (tMin != null && distMin < d0 && distMin < d2) 
			{
				// the closest point is on the curve
				nor.x = A.y + tMin * B.y;
				nor.y = -(A.x + tMin * B.x);
				nor.normalize(1);
				orientedDist = distMin;
				if ((x - posMin.x) * nor.x + (y - posMin.y) * nor.y < 0) 
				{
					nor.x *= -1;
					nor.y *= -1;
					orientedDist *= -1;
				}
				
				nearest.t = tMin;
				nearest.pos = posMin;
				nearest.nor = nor;
				nearest.dist = distMin;
				nearest.orientedDist = orientedDist;
				nearest.onCurve = true;
				return nearest;
			}
			
		} 
		// the closest point is one of the 2 end points
		if (d0 < d2) 
		{
			distMin = d0;
			tMin = 0;
			posMin.x = p0.x;
			posMin.y = p0.y;	
		} else 
		{
			distMin = d2;
			tMin = 1;
			posMin.x = p2.x;
			posMin.y = p2.y;
		}
		nor.x = x - posMin.x;
		nor.y = y - posMin.y;
		nor.normalize(1);
		
		nearest.t = tMin;
		nearest.pos = posMin;
		nearest.nor = nor;
		nearest.orientedDist = nearest.dist = distMin;
		nearest.onCurve = false;
		return nearest;
	}
	
	
	
	public function getPos(t:Number):Point
	{
		var a:Number = (1 - t) * (1 - t);
		var b:Number = 2 * t * (1 - t);
		var c:Number = t * t;
		pos.x = a * p0.x + b * p1.x + c * p2.x;
		pos.y = a * p0.y + b * p1.y + c * p2.y;
		return pos;
	}
	
	// (dP/dt)(t) = 2*(A + t*B)
	public function getSpeed(t:Number):Number
	{
		tan.x = A.x + t * B.x;
		tan.y = A.y + t * B.y;
		return 2 * Math.sqrt(tan.x * tan.x + tan.y * tan.y);
		//return 2*tan.getNorm();
	}
	
	public function getNor(t:Number):Point
	{
		nor.x = A.y + t * B.y;
		nor.y = -(A.x + t * B.x);
		// normalize:
		var lNorm:Number = Math.sqrt(nor.x * nor.x + nor.y * nor.y);
		if (lNorm > 0)
		{
			nor.x /= lNorm;
			nor.y /= lNorm;
		}
		return nor;
	}
	
	// a local duplicate & optimized version of com.gludion.utils.MathUtils.thirdDegreeEquation(a,b,c,d):Object
	//WARNING: s2, s3 may be non - null if count = 1.
	// use only result["s"+i] where i <= count
	private function thirdDegreeEquation(
								a:Number,
								b:Number,
								c:Number,
								d:Number
								):Object	// returns a {count:Number, s1:Number, s2:Number, s3:Number} object
	{
		if (Math.abs(a) > zeroMax)
		{
			// let's adopt form: x3 + ax2 + bx + d = 0
			var z:Number = a; // multi-purpose util variable
			a = b / z;
			b = c / z;
			c = d / z;
			// we solve using Cardan formula: http://fr.wikipedia.org/wiki/M%C3%A9thode_de_Cardan
			var p:Number = b - a * a / 3;
			var q:Number = a * (2 * a * a - 9 * b) / 27 + c;
			var p3:Number = p * p * p;
			var D:Number = q * q + 4 * p3 / 27;
			var offset:Number = -a / 3;
			if (D > zeroMax)
			{
				// D positive
				z = Math.sqrt(D)
				var u:Number = ( -q + z) / 2;
				var v:Number = ( -q - z) / 2;
				u = (u >= 0)? Math.pow(u, 1 / 3) : -Math.pow( -u, 1 / 3);
				v = (v >= 0)? Math.pow(v, 1 / 3) : -Math.pow( -v, 1 / 3);
				solution.s1 = u + v + offset;
				solution.count = 1;
				return solution;
			} else if (D < -zeroMax)
			{
				// D negative
				var u:Number = 2 * Math.sqrt( -p / 3);
				var v:Number = Math.acos( -Math.sqrt( -27 / p3) * q / 2) / 3;
				solution.s1 = u * Math.cos(v) + offset;
				solution.s2 = u * Math.cos(v + 2 * Math.PI / 3) + offset;
				solution.s3 = u * Math.cos(v + 4 * Math.PI / 3) + offset;
				solution.count = 3;
				return solution;
			} else
			{
				// D zero
				var u:Number;
				if (q < 0) u = Math.pow( -q / 2, 1 / 3);
				else u = -Math.pow( q / 2, 1 / 3);
				solution.s1 = 2*u + offset;
				solution.s2 = -u + offset;
				solution.count = 2;
				return solution;
			}
		} else
		{
			// a = 0, then actually a 2nd degree equation:
			// form : ax2 + bx + c = 0;
			a = b;
			b = c;
			c = d;
			if (Math.abs(a) <= zeroMax)
			{
				if (Math.abs(b) <= zeroMax) return null;
				else 
				{
					solution.s1 = -c / b;
					solution.count = 1;
					return solution;
				}
			}
			var D:Number = b*b - 4*a*c;
			if (D <= - zeroMax) return null;
			if (D > zeroMax)
			{
				// D positive
				D = Math.sqrt(D);
				solution.s1 = ( -b - D) / (2 * a);
				solution.s2 = ( -b + D) / (2 * a);
				solution.count = 2;
				return solution;
			} else if (D < - zeroMax)
			{
				// D negative
				return null;
			} else 
			{
				// D zero
				solution.s1 = -b / (2 * a);
				solution.count = 1
				return solution;
			}
		}
	}
	
	private function getDist(x1:Number, y1:Number, x2:Number, y2:Number):Number
	{
		return Math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
	}
}