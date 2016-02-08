function vmul(a,s)
	return {a[1]*s, a[2]*s}
end

function vfunc(a, func)
	return {func(a[1]), func(a[2])} 
end

function vmulx(a,s)
	return {a[1]*s, a[2]}
end

function vmuly(a,s)
	return {a[1], a[2]*s}
end

function vmulxy(a, x, y)
	return {a[1]*x, a[2]*y}
end

function vdot(a,b)
	return a[1]*b[1] + a[2]*b[2]
end

-- 2-norm
function vnorm(a)
	return math.sqrt(vdot(a,a))
end

-- inf-norm
function vmaxnorm(a)
	return math.max(math.abs(a[1]), math.abs(a[2]))
end

function vnormed(a)
	local l = vnorm(a)
	if math.abs(l) < 1e-4 then l = 1.0 end
	return vmul(a, 1/l)
end

function vstr(a)
	return a[1] .. ", " .. a[2]
end

function vsub(a,b)
	return {a[1]-b[1], a[2]-b[2]}
end

function clampUp(v, max)
	if v > max then return max end
	return v
end

function clampDown(v, min)
	if v < min then return min end
	return v
end

function clamp(v, min, max)
	return clampUp(clampDown(v, min), max)
end

function lerp(a,b,t)
	return a + (b-a)*t
end

function vlerp(a,b,t)
	return {lerp(a[1],b[1],t), lerp(a[2],b[2],t)}
end

function vadd(a,b)
	return {a[1]+b[1], a[2]+b[2]}
end

function vangle(a)
	return math.atan2(a[2], a[1])
end

function vortho(a)
	return {-a[2], a[1]}
end

function vclampLen(a, length)
	local l = vnorm(a)
	if l > length then
		return vmul(a, length/l)
	else
		return a
	end
end

function vrescale(a, length)
	return vmul(a, length/vnorm(a))
end

function vset(a, b)
	a[1] = b[1]
	a[2] = b[2]
end

function vret(a)
	return {a[1], a[2]}
end

function vpolar(angle, length)
	return {length*math.cos(angle), length*math.sin(angle)}
end

-- from standard basis into basis, baseA should be normalized
function vfromStd(a, baseA)
	local baseB = vortho(baseA)
	return {vdot(a, baseA), vdot(a, baseB)}
end

-- from baseA to standard basis, baseA should also be normalized
function vtoStd(a, baseA)
	local baseB = vortho(baseA)
	return vadd(vmul(baseA, a[1]), vmul(baseB, a[2]))
end

function vcopy(to, from)
	to[1] = from[1]
	to[2] = from[2]
end

function vrotate(v, angle) -- radians!
	local s = math.sin(angle)
	local c = math.cos(angle)
	return {c*v[1] - s*v[2], s*v[1] + c*v[2]}
end