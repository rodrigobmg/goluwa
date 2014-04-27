local syntax_process

do       
	local lex_setup = require("langtoolkit.lexer")
	local reader = require("langtoolkit.reader")
	 
	local colors = {
		default = Color(255, 255, 255),
		keyword = Color(127, 159, 191),
		identifier = Color(223, 223, 223),
		string = Color(191, 127, 127),
		number = Color(127, 191, 127),
		operator = Color(191, 191, 159),
		ccomment = Color(159, 159, 159),
		cmulticomment = Color(159, 159, 159),
		
		comment = Color(159, 159, 159),
		multicomment = Color(159, 159, 159),
	}

	local translate = {
		TK_ge = colors.operator, 
		TK_le = colors.operator, 
		TK_concat = colors.operator, 
		TK_eq = colors.operator,
		TK_label = colors.operator,
		["#"] = colors.operator,
		["]"] = colors.operator,
		[">"] = colors.operator,
		["/"] = colors.operator,
		["{"] = colors.operator,
		["}"] = colors.operator,
		[":"] = colors.operator,
		["*"] = colors.operator,
		["["] = colors.operator,
		["("] = colors.operator,
		[")"] = colors.operator,
		["+"] = colors.operator,
		[","] = colors.operator,
		["="] = colors.operator,
		["."] = colors.operator,
		["<"] = colors.operator,
		["-"] = colors.operator,
		[""] = colors.operator,
		TK_dots = colors.operator,
				
			
		TK_else = colors.keyword,
		TK_goto = colors.keyword,
		TK_if = colors.keyword,
		TK_nil = colors.keyword,
		TK_end = colors.keyword,
		TK_or = colors.keyword,
		TK_return = colors.keyword,
		TK_true = colors.keyword,
		TK_elseif = colors.keyword,
		TK_function = colors.keyword,
		TK_while = colors.keyword,
		TK_and = colors.keyword,
		TK_then = colors.keyword,
		TK_in = colors.keyword,
		TK_for = colors.keyword,
		TK_do = colors.keyword,
		TK_for = colors.keyword,
		TK_false = colors.keyword,
		TK_break = colors.keyword,
		TK_not = colors.keyword,

		TK_local = colors.keyword,

		TK_ne = colors.keyword,
		["/37"] = colors.keyword,
			
		TK_number = colors.number,
		TK_string = colors.string,
		TK_name = colors.default,
	} 
  
  
	function syntax_process(str, markup)
		reader.string_init(str)
		local ls = lex_setup(reader.string, str)

		local last_pos = 1
		local last_color
			
		for i = 1, 1000 do
			local ok, msg = pcall(ls.next, ls)
			
			if not ok then
				local tbl = msg:explode("\n")
				markup:AddString(str:sub(-ls.p))
				break
			end
					
			if #ls.token == 1 then
				local color = colors.operator
				if color ~= last_color then   
					markup:AddColor(color)
					last_color = color
				end
			else
				local color = translate[ls.token] or colors.comment
				if color ~= last_color then
					markup:AddColor(color)
					last_color = color
				end
			end
						
			markup:AddString(str:sub(last_pos-1, ls.p-2))
			
			last_pos = ls.p 
								
			if ls.token == "TK_eof" then break end
		end
		
		markup:AddString(str:sub(last_pos-1, last_pos-2))
		  		  
		return out
	end  
end 
   
local frame = utilities.RemoveOldObject(aahh.Create("frame"), "markup")
frame:SetSize(1000, 1000)
frame:RequestLayout(true) 

local scroll = aahh.Create("scrollable", frame)
scroll:Dock("fill")

local markup = aahh.Create("text_input")  
markup:SetMultiLine(true)
markup:SetEditorMode(true)
markup:SetWrap(false )
markup.markup:SetFastMode(true)
scroll:SetPanel(markup)  

function markup:OnTextChanged()
	self:SizeToContents()
end    
 
syntax_process(vfs.Read("lua/tests/lua_editor.lua") or "local hello = ''\n asdasdasd = 1234\n --[[it's a comment]] local test \n --it's really powerful\n", markup.markup)  

window.SetSize(Vec2(1680, 1050)) 