local a=require("widgets/widget")local b=require("widgets/image")local c=require("easing")local d,e=RESOLUTION_X/2,RESOLUTION_Y/2;local f,g=TheSim:GetScreenSize()local function h(i,j)local k,l=TheWorld.minimap.MiniMap:WorldPosToMapPos(i,j,0)local m=(k*d+d)/RESOLUTION_X*f;local n=(l*e+e)/RESOLUTION_Y*g;return m,n end;local o=Class(a,function(self,p,q)a._ctor(self,"PersistentMapIcons")self.root=self:AddChild(a("root"))self.zoomed_scale={}self.mapicons={}for r=1,20 do self.zoomed_scale[r]=q-c.outExpo(r-1,0,q-0.25,8)end;local s=p.OnUpdate;p.OnUpdate=function(p,...)s(p,...)local q=self.zoomed_scale[TheWorld.minimap.MiniMap:GetZoom()]for t,u in ipairs(self.mapicons)do local i,v=h(u.pos.x,u.pos.z)u.icon:SetPosition(i,v)u.icon:SetScale(q)end end end)function o:AddMapIcon(w,x,y)local z=self.root:AddChild(b(w,x))table.insert(self.mapicons,{icon=z,pos=y})end;return o