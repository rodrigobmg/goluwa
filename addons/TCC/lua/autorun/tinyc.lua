local header = [[
struct TCCState;
typedef struct TCCState TCCState;

TCCState *tcc_new(void);

void tcc_delete(TCCState *s);
void tcc_set_lib_path(TCCState *s, const char *path);
void tcc_set_error_func(TCCState *s, void *error_opaque, void (*error_func)(void *opaque, const char *msg));
int tcc_set_options(TCCState *s, const char *str);
int tcc_add_include_path(TCCState *s, const char *pathname);
int tcc_add_sysinclude_path(TCCState *s, const char *pathname);
void tcc_define_symbol(TCCState *s, const char *sym, const char *value);
void tcc_undefine_symbol(TCCState *s, const char *sym);
int tcc_add_file(TCCState *s, const char *filename);
int tcc_compile_string(TCCState *s, const char *buf);
int tcc_set_output_type(TCCState *s, int output_type);
int tcc_add_library_path(TCCState *s, const char *pathname);
int tcc_add_library(TCCState *s, const char *libraryname);
int tcc_add_symbol(TCCState *s, const char *name, const void *val);
int tcc_output_file(TCCState *s, const char *filename);
int tcc_run(TCCState *s, int argc, char **argv);


int tcc_relocate(TCCState *s1, int *ptr);

void *tcc_get_symbol(TCCState *s, const char *name);
]]

ffi.cdef(header)

local module = ffi.load("libtcc")

local META = {}
do -- meta
	META.Type = "TCCState"
	META.__index = META
	
	for def in header:gmatch("(tcc_.-)%(TCCState") do		
		-- turn it into CamelCase
		local friendly = def:gsub("(_.)", function(char) 
			return char:sub(2):upper()
		end):sub(4)

		META[friendly] = function(self, ...)
			local err = module[def](self.__ptr, ...)
			
			if type(err) == "number" and err == -1 then
				return err
			end
			
			return err
		end
	end
	
	-- change output type to use strings as enums instead
	local output_types = {"memory", "exe", "dll", "obj", "preprocess"}

	function META:SetOutputType(output_type)
		return module.tcc_set_output_type(self.__ptr, output_types[output_type])
	end
	
	if mmyy then
		
		-- add Remove with NULL behavior 
		function META:Remove()
			module.tcc_delete(self.__ptr)
			utilities.MakeNull(self)
		end
		
		-- and remove Delete
		META.Delete = nil
	end
	
	function META:GetFunction(name, ret, args)
		if not self.relocated then
			self:Relocate(ffi.cast("int*", 1))			
			self.relocated = true
		end
	
		local ptr = self:GetSymbol(name)
		local func = ffi.cast(("%s (*)(%s)"):format(ret, args or ""), ptr) 
		
		return func
	end
end

function TCCState()
	local self = setmetatable({}, META)
	self.__ptr = module.tcc_new()
	
	if mmyy then		
		-- addons/*/include
		self:AddIncludePath(R"include/")
		
		-- addons/*/lib 
		self:AddLibraryPath(R"lib/" .. ffi.arch .. "/")
	end
		
	return self
end

console.AddCommand("test_tcc", function()
	local state = TCCState()

	state:CompileString([[	
		float LOL(float* bar)
		{	
			return bar[0] + bar[1] + bar[2] + bar[3];
		}
	]])

	local func = state:GetFunction("LOL", "float", "float[4]")
	print(func(ffi.new("float[4]", {2,2,4.5,4})))
end)