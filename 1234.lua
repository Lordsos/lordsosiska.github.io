--!native
--!optimize 2
--!divine-intellect
-- https://discord.gg/wx4ThpAsmw

local function string_find(s, pattern)
	return string.find(s, pattern, nil, true)
end

local function ArrayToDict(t, hydridMode, valueOverride, typeStrict)
	local tmp = {}

	if hydridMode then
		for any1, any2 in t do
			if type(any1) == "number" then
				tmp[any2] = valueOverride or true
			elseif type(any2) == "table" then
				tmp[any1] = ArrayToDict(any2, hydridMode)
			else
				tmp[any1] = any2
			end
		end
	else
		for _, key in t do
			if not typeStrict or typeStrict and type(key) == typeStrict then
				tmp[key] = true
			end
		end
	end

	return tmp
end

local global_container
do
	local filename = "UniversalMethodFinder"

	local finder
	finder, global_container = loadstring(
		game:HttpGet("https://raw.githubusercontent.com/luau/SomeHub/main/" .. filename .. ".luau", true),
		filename
	)()

	finder({
		base64encode = 'local a={...}local b=a[1]local function c(a,b)return string.find(a,b,nil,true)end;return c(b,"encode")and(c(b,"base64")or c(string.lower(tostring(a[2])),"base64"))',
		gethiddenproperty = 'string.find(...,"get",nil,true) and string.find(...,"h",nil,true) and string.find(...,"prop",nil,true) and string.sub(...,#...) ~= "s"',
		gethui = 'string.find(...,"get",nil,true) and string.find(...,"h",nil,true) and string.find(...,"ui",nil,true)',
		getnilinstances = 'string.find(...,"nil",nil,true) and string.find(...,"get",nil,true) and string.sub(...,#...) == "s"',
		getscriptbytecode = 'string.find(...,"get",nil,true) and string.find(...,"bytecode",nil,true)',
		protectgui = 'string.find(...,"protect",nil,true) and string.find(...,"ui",nil,true) and not string.find(...,"un",nil,true)',
		setthreadidentity = 'string.find(...,"identity",nil,true) and string.find(...,"set",nil,true)',
	}, true, 10)
end

local identify_executor = identifyexecutor or getexecutorname or whatexecutor
local EXECUTOR_NAME = identify_executor and identify_executor() or ""

local gethiddenproperty = global_container.gethiddenproperty
local appendfile = appendfile
local readfile = readfile
local writefile = writefile
local getscriptbytecode = global_container.getscriptbytecode
local base64encode = global_container.base64encode

local service = setmetatable({}, {
	__index = function(self, serviceName)
		local o, s = pcall(Instance.new, serviceName)
		local Service = o and s
			or game:GetService(serviceName)
			or settings():GetService(serviceName)
			or UserSettings():GetService(serviceName)

		if Service then
			self[serviceName] = Service
		end
		return Service
	end,
})

local gethiddenproperty_fallback
do
	local UGCValidationService

	gethiddenproperty_fallback = function(instance, propertyName)
		if not UGCValidationService then
			UGCValidationService = service.UGCValidationService
		end
		return UGCValidationService:GetPropertyValue(instance, propertyName)
	end
	
	if gethiddenproperty then
		local o, r = pcall(gethiddenproperty, workspace, "StreamOutBehavior")
		if not o or r ~= nil and typeof(r) ~= "EnumItem" then
			gethiddenproperty = nil
		else
			o, r = pcall(gethiddenproperty, Instance.new("AnimationRigData", Instance.new("Folder")), "parent")

			if o and r ~= nil and type(r) ~= "string" then
				gethiddenproperty = nil
			end
		end
	end
	
	local function benchmark(f1, f2, ...)
		local ranking = table.create(2)
		for i, f in { f1, f2 } do
			local start = os.clock()
			for _ = 1, 50 do
				f(...)
			end
			ranking[i] = { t = os.clock() - start, f = f }
		end
		table.sort(ranking, function(a, b)
			return a.t < b.t
		end)
		return ranking[1].f
	end

	local test_str = string.rep("\1\0\0\0\1\2\3\4\5\6\7", 50)

	do
		if not bit32.byteswap or not pcall(bit32.byteswap, 1) then
			bit32 = table.clone(bit32)

			local function tobit(num)
				num %= (bit32.bxor(num, 32))
				if 0x80000000 < num then
					num -= bit32.bxor(num, 32)
				end
				return num
			end

			bit32.byteswap = function(num)
				local BYTE_SIZE = 8
				local MAX_BYTE_VALUE = 255

				num %= bit32.bxor(2, 32)

				local a = bit32.band(num, MAX_BYTE_VALUE)
				num = bit32.rshift(num, BYTE_SIZE)

				local b = bit32.band(num, MAX_BYTE_VALUE)
				num = bit32.rshift(num, BYTE_SIZE)

				local c = bit32.band(num, MAX_BYTE_VALUE)
				num = bit32.rshift(num, BYTE_SIZE)

				local d = bit32.band(num, MAX_BYTE_VALUE)
				num = tobit(bit32.lshift(bit32.lshift(bit32.lshift(a, BYTE_SIZE) + b, BYTE_SIZE) + c, BYTE_SIZE) + d)
				return num
			end

			table.freeze(bit32)
		end

		local rbxcrypt_base64encode
		pcall(function()
			local b64_enc_buf = loadstring(
				game:HttpGet(
					"https://raw.githubusercontent.com/daily3014/rbx-cryptography/refs/heads/main/src/Utilities/Base64.luau",
					true
				),
				"Base64"
			)().Encode
			rbxcrypt_base64encode = function(raw)
				return buffer.tostring(b64_enc_buf(buffer.fromstring(raw)))
			end
		end)

		if base64encode and base64encode("\1\0\0\0\1") == "AQAAAAE=" then
			if rbxcrypt_base64encode then
				base64encode = benchmark(base64encode, rbxcrypt_base64encode, test_str)
			end
		else
			base64encode = rbxcrypt_base64encode
		end

		assert(base64encode, "base64encode not found")
	end
end

local SharedStrings = {
	data = {},
	identifiers = setmetatable({
		identifier = 1e15,
	}, {
		__index = function(self, str)
			local Identifier = base64encode(tostring(self.identifier))
			self.identifier += 1
			self[str] = Identifier
			SharedStrings.data[Identifier] = str
			return Identifier
		end,
	}),
}

local inherited_properties = {}
local default_instances = {}
local referents, ref_size = {}, 0

local function GetRef(instance)
	local ref = referents[instance]
	if not ref then
		ref = ref_size
		referents[instance] = ref
		ref_size += 1
	end
	return ref
end

local function index(self, index_name)
	return self[index_name]
end

local version = version
if not version then
	version = function()
		return "UNKNOWN"
	end
end

local CLIENT_VERSION = tonumber(string.split(version(), ".")[2]) or 9e9

local attr_Type_IDs = {
	string = 0x02,
	boolean = 0x03,
	int32 = 0x04,
	number = 0x06,
	UDim = 0x09,
	UDim2 = 0x0A,
	Ray = 0x0B,
	Faces = 0x0C,
	Axes = 0x0D,
	BrickColor = 0x0E,
	Color3 = 0x0F,
	Vector2 = 0x10,
	Vector3 = 0x11,
	Vector2int16 = 0x12,
	Vector3int16 = 0x13,
	CFrame = 0x14,
	EnumItem = 0x15,
	NumberSequence = 0x17,
	NumberSequenceKeypoint = 0x18,
	ColorSequence = 0x19,
	ColorSequenceKeypoint = 0x1A,
	NumberRange = 0x1B,
	Rect = 0x1C,
	PhysicalProperties = 0x1D,
	Region3 = 0x1F,
	Region3int16 = 0x20,
	Font = 0x21,
	SecurityCapabilities = 0x22,
	Path2DControlPoint = 0x23,
}

local CFrame_Rotation_IDs = {
	["\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63"] = 0x02,
	["\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0"] = 0x03,
	["\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191"] = 0x05,
	["\0\0\128\63\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\191\0\0\0\0"] = 0x06,
	["\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191"] = 0x07,
	["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0"] = 0x09,
	["\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\63"] = 0x0a,
	["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0"] = 0x0c,
	["\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\63\0\0\0\0\0\0\0\0"] = 0x0d,
	["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0"] = 0x0e,
	["\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\63\0\0\0\0\0\0\0\0"] = 0x10,
	["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\128"] = 0x11,
	["\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191"] = 0x14,
	["\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\128"] = 0x15,
	["\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63"] = 0x17,
	["\0\0\128\191\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\191\0\0\0\128"] = 0x18,
	["\0\0\0\0\0\0\128\63\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63"] = 0x19,
	["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0"] = 0x1b,
	["\0\0\0\0\0\0\128\191\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\191"] = 0x1c,
	["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0"] = 0x1e,
	["\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\191\0\0\0\0\0\0\0\0"] = 0x1f,
	["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\0"] = 0x20,
	["\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\191\0\0\0\0\0\0\0\0"] = 0x22,
	["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\191\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\128"] = 0x23,
}

local BASE_CAPABILITIES
pcall(function()
	BASE_CAPABILITIES = SecurityCapabilities.new()
end)

local CAPABILITY_BITS = {
	Plugin = 2 ^ 0,
	LocalUser = 2 ^ 1,
	WritePlayer = 2 ^ 2,
	RobloxScript = 2 ^ 3,
	RobloxEngine = 2 ^ 4,
	NotAccessible = 2 ^ 5,
	RunClientScript = 2 ^ 8,
	RunServerScript = 2 ^ 9,
	Unknown = 2 ^ 10,
	AccessOutsideWrite = 2 ^ 11,
	Unassigned = 2 ^ 15,
	AssetRequire = 2 ^ 16,
	LoadString = 2 ^ 17,
	ScriptGlobals = 2 ^ 18,
	CreateInstances = 2 ^ 19,
	Basic = 2 ^ 20,
	Audio = 2 ^ 21,
	DataStore = 2 ^ 22,
	Network = 2 ^ 23,
	Physics = 2 ^ 24,
	UI = 2 ^ 25,
	CSG = 2 ^ 26,
	Chat = 2 ^ 27,
	Animation = 2 ^ 28,
	Avatar = 2 ^ 29,
	Input = 2 ^ 30,
	Environment = 2 ^ 31,
	RemoteEvent = 2 ^ 32,
	LegacySound = 2 ^ 33,
	Players = 2 ^ 34,
	CapabilityControl = 2 ^ 35,
	RemoteCommand = 2 ^ 59,
	InternalTest = 2 ^ 60,
	PluginOrOpenCloud = 2 ^ 61,
	Assistant = 2 ^ 62,
}

local function __COUNT_CAPABILITY_BITS(raw)
	local result = 0
	for _, flag in string.split(tostring(raw), " | ") do
		local bit = CAPABILITY_BITS[flag]
		if bit then
			result += bit
		end
	end
	return result
end

local function __COUNT_BITS(...)
	local Value = 0
	for i, bit in { ... } do
		if bit then
			Value += 2 ^ (i - 1)
		end
	end
	return Value
end

local Binary_Descriptors
Binary_Descriptors = {
	__PACK_MULTIPLE = function(descriptor, value1, value2, value3)
		local buf1, size1 = descriptor(value1)
		local buf2, size2 = descriptor(value2)

		local len = size1 + size2
		local buf3, size3

		if value3 ~= nil then
			buf3, size3 = descriptor(value3)
			len += size3
		end

		local b = buffer.create(len)

		buffer.copy(b, 0, buf1)
		buffer.copy(b, size1, buf2)

		if value3 ~= nil then
			buffer.copy(b, size1 + size2, buf3)
		end

		return b, len
	end,
	__construct_Sequence = function(keypoint_handler, keypointSize)
		return function(raw)
			local Keypoints = raw.Keypoints
			local Keypoints_n = #Keypoints

			local len = 4 + keypointSize * Keypoints_n
			local b = buffer.create(len)

			buffer.writeu32(b, 0, Keypoints_n)

			local offset = 4
			for _, keypoint in Keypoints do
				keypoint_handler(keypoint, b, offset)
				offset += keypointSize
			end

			return b, len
		end
	end,
	__PACK_F32 = nil,
	__PACK_I16 = nil,
	__construct__PACKER = function(float)
		local writeFunc = float and buffer.writef32 or buffer.writei16
		local elementSize = float and 4 or 2

		return function(X, Y, Z)
			local len = Z and (elementSize * 3) or (elementSize * 2)
			local b = buffer.create(len)

			writeFunc(b, 0, X)
			writeFunc(b, elementSize, Y)
			if Z then
				writeFunc(b, elementSize * 2, Z)
			end

			return b, len
		end
	end,
	["string"] = function(raw)
		local raw_len = #raw
		local len = 4 + raw_len

		local b = buffer.create(len)

		buffer.writeu32(b, 0, raw_len)
		buffer.writestring(b, 4, raw)

		return b, len
	end,
	["boolean"] = function(raw)
		local b = buffer.create(1)
		buffer.writeu8(b, 0, raw and 1 or 0)
		return b, 1
	end,
	["number"] = function(raw)
		local b = buffer.create(8)
		buffer.writef64(b, 0, raw)
		return b, 8
	end,
	["UDim"] = function(raw)
		local b = buffer.create(8)
		buffer.writef32(b, 0, raw.Scale)
		buffer.writei32(b, 4, raw.Offset)
		return b, 8
	end,
	["UDim2"] = function(raw)
		return Binary_Descriptors.__PACK_MULTIPLE(Binary_Descriptors.UDim, raw.X, raw.Y)
	end,
	["Ray"] = function(raw)
		return Binary_Descriptors.__PACK_MULTIPLE(Binary_Descriptors.Vector3, raw.Origin, raw.Direction)
	end,
	["Faces"] = function(raw)
		local b = buffer.create(4)
		buffer.writeu32(b, 0, __COUNT_BITS(raw.Right, raw.Top, raw.Back, raw.Left, raw.Bottom, raw.Front))
		return b, 4
	end,
	["Axes"] = function(raw)
		local b = buffer.create(4)
		buffer.writeu32(b, 0, __COUNT_BITS(raw.X, raw.Y, raw.Z))
		return b, 4
	end,
	["BrickColor"] = function(raw)
		local b = buffer.create(4)
		buffer.writeu32(b, 0, raw.Number)
		return b, 4
	end,
	["Color3"] = function(raw)
		return Binary_Descriptors.__PACK_F32(raw.R, raw.G, raw.B)
	end,
	["Vector2"] = function(raw)
		return Binary_Descriptors.__PACK_F32(raw.X, raw.Y)
	end,
	["Vector3"] = function(raw)
		return Binary_Descriptors.__PACK_F32(raw.X, raw.Y, raw.Z)
	end,
	["Vector2int16"] = function(raw)
		return Binary_Descriptors.__PACK_I16(raw.X, raw.Y)
	end,
	["Vector3int16"] = function(raw)
		return Binary_Descriptors.__PACK_I16(raw.X, raw.Y, raw.Z)
	end,
	["CFrame"] = function(raw)
		local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = raw:GetComponents()
		local rotation_ID
		do
			local b = buffer.create(36)

			buffer.writef32(b, 0, R00)
			buffer.writef32(b, 4, R01)
			buffer.writef32(b, 8, R02)
			buffer.writef32(b, 12, R10)
			buffer.writef32(b, 16, R11)
			buffer.writef32(b, 20, R12)
			buffer.writef32(b, 24, R20)
			buffer.writef32(b, 28, R21)
			buffer.writef32(b, 32, R22)

			rotation_ID = CFrame_Rotation_IDs[buffer.tostring(b)]
		end

		local len = rotation_ID and 13 or 49
		local b = buffer.create(len)

		local __PACK_F32 = Binary_Descriptors.__PACK_F32
		local pos = __PACK_F32(X, Y, Z)
		buffer.copy(b, 0, pos)

		if rotation_ID then
			buffer.writeu8(b, 12, rotation_ID)
		else
			buffer.writeu8(b, 12, 0x0)

			local xBasis = __PACK_F32(R00, R01, R02)
			buffer.copy(b, 13, xBasis)
			local yBasis = __PACK_F32(R10, R11, R12)
			buffer.copy(b, 13 + 12, yBasis)
			local zBasis = __PACK_F32(R20, R21, R22)
			buffer.copy(b, 13 + 24, zBasis)
		end

		return b, len
	end,
	["EnumItem"] = function(raw)
		local b_Name, Name_size = Binary_Descriptors.string(tostring(raw.EnumType))

		local len = Name_size + 4
		local b = buffer.create(len)

		buffer.copy(b, 0, b_Name)
		buffer.writeu32(b, Name_size, raw.Value)

		return b, len
	end,
	["NumberSequence"] = nil,
	["NumberSequenceKeypoint"] = function(keypoint, b, offset)
		if not b then
			return Binary_Descriptors.__PACK_F32(keypoint.Envelope, keypoint.Time, keypoint.Value)
		end

		buffer.writef32(b, offset, keypoint.Envelope)
		offset += 4
		buffer.writef32(b, offset, keypoint.Time)
		offset += 4
		buffer.writef32(b, offset, keypoint.Value)
	end,
	["ColorSequence"] = nil,
	["ColorSequenceKeypoint"] = function(keypoint, b, offset)
		local Value = Binary_Descriptors.Color3(keypoint.Value)

		if not b then
			b = buffer.create(20)
			offset = 0
		end

		buffer.writef32(b, offset, 0)
		offset += 4
		buffer.writef32(b, offset, keypoint.Time)
		offset += 4
		buffer.copy(b, offset, Value)

		return b, 20
	end,
	["NumberRange"] = function(raw)
		return Binary_Descriptors.__PACK_F32(raw.Min, raw.Max)
	end,
	["Rect"] = function(raw)
		return Binary_Descriptors.__PACK_MULTIPLE(Binary_Descriptors.Vector2, raw.Min, raw.Max)
	end,
	["PhysicalProperties"] = function(raw)
		local len = 1
		if raw then
			len += 24
		end
		local b = buffer.create(len)

		buffer.writeu8(b, 0, raw and 3 or 0)

		if raw then
			buffer.writef32(b, 1, raw.Density)
			buffer.writef32(b, 5, raw.Friction)
			buffer.writef32(b, 9, raw.Elasticity)
			buffer.writef32(b, 13, raw.FrictionWeight)
			buffer.writef32(b, 17, raw.ElasticityWeight)
			buffer.writef32(b, 21, raw.AcousticAbsorption)
		end

		return b, len
	end,
	["Region3"] = function(raw)
		local Translation = raw.CFrame.Position
		local HalfSize = raw.Size * 0.5

		return Binary_Descriptors.__PACK_MULTIPLE(
			Binary_Descriptors.Vector3,
			Translation - HalfSize,
			Translation + HalfSize
		)
	end,
	["Region3int16"] = function(raw)
		return Binary_Descriptors.__PACK_MULTIPLE(Binary_Descriptors.Vector3int16, raw.Min, raw.Max)
	end,
	["Font"] = 636 < CLIENT_VERSION and function(raw)
		local string__descriptor = Binary_Descriptors.string

		local b_Family, Family_size = string__descriptor(raw.Family)
		local b_CachedFaceId, CachedFaceId_size = string__descriptor("")

		local len = 3 + Family_size + CachedFaceId_size
		local b = buffer.create(len)

		local ok_w, weight = pcall(index, raw, "Weight")
		local ok_s, style = pcall(index, raw, "Style")

		buffer.writeu16(b, 0, ok_w and weight.Value or 0)
		buffer.writeu8(b, 2, ok_s and style.Value or 0)

		buffer.copy(b, 3, b_Family)
		buffer.copy(b, 3 + Family_size, b_CachedFaceId)

		return b, len
	end or function(raw)
		local string__descriptor = Binary_Descriptors.string

		local b_Family, Family_size = string__descriptor(raw.Family)
		local b_CachedFaceId, CachedFaceId_size = string__descriptor("")

		local len = 3 + Family_size + CachedFaceId_size
		local b = buffer.create(len)

		local FontString = tostring(raw)

		local EmptyWeight = string_find(FontString, "Weight = ,")
		local EmptyStyle = string_find(FontString, "Style =  }")

		buffer.writeu16(b, 0, EmptyWeight and 0 or raw.Weight.Value)
		buffer.writeu8(b, 2, EmptyStyle and 0 or raw.Style.Value)

		buffer.copy(b, 3, b_Family)
		buffer.copy(b, 3 + Family_size, b_CachedFaceId)

		return b, len
	end,
	["SecurityCapabilities"] = function(raw)
		local b = buffer.create(8)

		if raw == BASE_CAPABILITIES then
			return b, 8
		end

		local capabilities = __COUNT_CAPABILITY_BITS(raw)

		local low = bit32.band(capabilities, 0xFFFFFFFF)
		local high = (capabilities - low) / 0x100000000

		buffer.writei32(b, 0, low)
		buffer.writei32(b, 4, high)

		return b, 8
	end,
	["Path2DControlPoint"] = function(raw)
		return Binary_Descriptors.__PACK_MULTIPLE(
			Binary_Descriptors.UDim2,
			raw.Position,
			raw.LeftTangent,
			raw.RightTangent
		)
	end,
}

do
	Binary_Descriptors["NumberSequence"] =
		Binary_Descriptors.__construct_Sequence(Binary_Descriptors.NumberSequenceKeypoint, 12)

	Binary_Descriptors["ColorSequence"] =
		Binary_Descriptors.__construct_Sequence(Binary_Descriptors.ColorSequenceKeypoint, 20)
end

do
	Binary_Descriptors.__PACK_F32 = Binary_Descriptors.__construct__PACKER(true)
	Binary_Descriptors.__PACK_I16 = Binary_Descriptors.__construct__PACKER()
end

local ESCAPES_PATTERN = "[&<>\"'\0\1-\9\11-\12\14-\31\127-\255]"
local ESCAPES = {
	["&"] = "&amp;",
	["<"] = "&lt;",
	[">"] = "&gt;",
	['"'] = "&#34;",
	["'"] = "&#39;",
	["\0"] = "",
}

for rangeStart, rangeEnd in string.gmatch(ESCAPES_PATTERN, "(.)%-(.)") do
	for charCode = string.byte(rangeStart), string.byte(rangeEnd) do
		ESCAPES[string.char(charCode)] = "&#" .. charCode .. ";"
	end
end

local XML_Descriptors
XML_Descriptors = {
	__CDATA = function(raw)
		return "<![CDATA[" .. raw .. "]]>"
	end,
	__ENUM = function(raw)
		return raw.Value, "token"
	end,
	__NORMALIZE_NUMBER = function(raw)
		if raw ~= raw then
			return "NAN"
		elseif raw == math.huge then
			return "INF"
		elseif raw == -math.huge then
			return "-INF"
		end
		return raw
	end,
	__NORMALIZE_RANGE = function(raw)
		return raw ~= raw and "0" or raw
	end,
	__MINMAX = function(min, max, descriptor)
		return "<min>" .. descriptor(min) .. "</min><max>" .. descriptor(max) .. "</max>"
	end,
	__PROTECTEDSTRING = function(raw)
		return string_find(raw, "]]>") and string.gsub(raw, ESCAPES_PATTERN, ESCAPES) or XML_Descriptors.__CDATA(raw)
	end,
	__construct_Sequence = function(keypoint_handler)
		return function(raw)
			local sequence = ""
			for _, keypoint in raw.Keypoints do
				sequence ..= keypoint_handler(keypoint)
			end
			return sequence
		end
	end,
	__VECTOR = function(X, Y, Z)
		local Value = "<X>" .. X .. "</X><Y>" .. Y .. "</Y>"
		if Z then
			Value ..= "<Z>" .. Z .. "</Z>"
		end
		return Value
	end,
	Axes = function(raw)
		return "<axes>" .. __COUNT_BITS(raw.X, raw.Y, raw.Z) .. "</axes>"
	end,
	BinaryString = function(raw)
		return raw == "" and "" or base64encode(raw)
	end,
	BrickColor = function(raw)
		return raw.Number
	end,
	CFrame = function(raw)
		local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = raw:GetComponents()
		return XML_Descriptors.__VECTOR(X, Y, Z)
			.. "<R00>"
			.. R00
			.. "</R00><R01>"
			.. R01
			.. "</R01><R02>"
			.. R02
			.. "</R02><R10>"
			.. R10
			.. "</R10><R11>"
			.. R11
			.. "</R11><R12>"
			.. R12
			.. "</R12><R20>"
			.. R20
			.. "</R20><R21>"
			.. R21
			.. "</R21><R22>"
			.. R22
			.. "</R22>",
			"CoordinateFrame"
	end,
	Color3 = function(raw)
		return "<R>" .. raw.R .. "</R><G>" .. raw.G .. "</G><B>" .. raw.B .. "</B>"
	end,
	Color3uint8 = function(raw)
		return 0xFF000000
			+ (math.floor(raw.R * 255) * 0x10000)
			+ (math.floor(raw.G * 255) * 0x100)
			+ math.floor(raw.B * 255)
	end,
	ColorSequence = nil,
	ColorSequenceKeypoint = function(keypoint)
		local __NORMALIZE_RANGE = XML_Descriptors.__NORMALIZE_RANGE
		local color3 = keypoint.Value

		return __NORMALIZE_RANGE(keypoint.Time)
			.. " "
			.. __NORMALIZE_RANGE(color3.R)
			.. " "
			.. __NORMALIZE_RANGE(color3.G)
			.. " "
			.. __NORMALIZE_RANGE(color3.B)
			.. " 0 "
	end,
	Content = function(raw)
		local SourceType = raw.SourceType
		return SourceType == Enum.ContentSourceType.None and "<null></null>"
			or SourceType == Enum.ContentSourceType.Uri and "<uri>" .. XML_Descriptors.string(raw.Uri) .. "</uri>"
			or SourceType == Enum.ContentSourceType.Object and "<Ref>" .. GetRef(raw.Object) .. "</Ref>"
			or SourceType == Enum.ContentSourceType.Opaque and "<Ref>" .. GetRef(raw.Opaque) .. "</Ref>"
	end,
	ContentId = function(raw)
		return raw == "" and "<null></null>" or "<url>" .. XML_Descriptors.string(raw) .. "</url>", "Content"
	end,
	CoordinateFrame = function(raw)
		return "<CFrame>" .. XML_Descriptors.CFrame(raw) .. "</CFrame>"
	end,
	Faces = function(raw)
		return "<faces>" .. __COUNT_BITS(raw.Right, raw.Top, raw.Back, raw.Left, raw.Bottom, raw.Front) .. "</faces>"
	end,
	Font = 636 < CLIENT_VERSION
			and function(raw)
				local ok_w, weight = pcall(index, raw, "Weight")
				local ok_s, style = pcall(index, raw, "Style")

				return "<Family>"
					.. XML_Descriptors.ContentId(raw.Family)
					.. "</Family><Weight>"
					.. (ok_w and XML_Descriptors.__ENUM(weight) or "")
					.. "</Weight><Style>"
					.. (ok_s and style.Name or "")
					.. "</Style>"
			end
		or function(raw)
			local FontString = tostring(raw)

			local EmptyWeight = string_find(FontString, "Weight = ,")
			local EmptyStyle = string_find(FontString, "Style =  }")

			return "<Family>"
				.. XML_Descriptors.ContentId(raw.Family)
				.. "</Family><Weight>"
				.. (EmptyWeight and "" or XML_Descriptors.__ENUM(raw.Weight))
				.. "</Weight><Style>"
				.. (EmptyStyle and "" or raw.Style.Name)
				.. "</Style>"
		end,
	NetAssetRef = nil,
	NumberRange = function(raw)
		local __NORMALIZE_RANGE = XML_Descriptors.__NORMALIZE_RANGE
		return __NORMALIZE_RANGE(raw.Min) .. " " .. __NORMALIZE_RANGE(raw.Max)
	end,
	NumberSequence = nil,
	NumberSequenceKeypoint = function(keypoint)
		local __NORMALIZE_RANGE = XML_Descriptors.__NORMALIZE_RANGE

		return __NORMALIZE_RANGE(keypoint.Time)
			.. " "
			.. __NORMALIZE_RANGE(keypoint.Value)
			.. " "
			.. __NORMALIZE_RANGE(keypoint.Envelope)
			.. " "
	end,
	PhysicalProperties = function(raw)
		local CustomPhysics = "<CustomPhysics>" .. XML_Descriptors.bool(raw and true or false) .. "</CustomPhysics>"

		return raw
				and CustomPhysics .. "<Density>" .. raw.Density .. "</Density><Friction>" .. raw.Friction .. "</Friction><Elasticity>" .. raw.Elasticity .. "</Elasticity><FrictionWeight>" .. raw.FrictionWeight .. "</FrictionWeight><ElasticityWeight>" .. raw.ElasticityWeight .. "</ElasticityWeight><AcousticAbsorption>" .. raw.AcousticAbsorption .. "</AcousticAbsorption>"
			or CustomPhysics
	end,
	Ray = function(raw)
		local vector3 = XML_Descriptors.Vector3
		return "<origin>" .. vector3(raw.Origin) .. "</origin><direction>" .. vector3(raw.Direction) .. "</direction>"
	end,
	Rect = function(raw)
		return XML_Descriptors.__MINMAX(raw.Min, raw.Max, XML_Descriptors.Vector2), "Rect2D"
	end,
	Region3 = function(raw)
		local Translation = raw.CFrame.Position
		local HalfSize = raw.Size * 0.5

		return XML_Descriptors.__MINMAX(
			Translation - HalfSize,
			Translation + HalfSize,
			XML_Descriptors.Vector3
		)
	end,
	Region3int16 = function(raw)
		return XML_Descriptors.__MINMAX(raw.Min, raw.Max, XML_Descriptors.Vector3int16)
	end,
	SharedString = function(raw)
		raw = raw == "" and "" or base64encode(raw)
		local Identifier = SharedStrings.identifiers[raw]

		if SharedStrings.data[Identifier] == nil then
			SharedStrings.data[Identifier] = raw
		end

		return Identifier
	end,
	SecurityCapabilities = function(raw)
		if raw == BASE_CAPABILITIES then
			return 0
		end
		return __COUNT_CAPABILITY_BITS(raw)
	end,
	UDim = function(raw)
		return "<S>" .. raw.Scale .. "</S><O>" .. raw.Offset .. "</O>"
	end,
	UDim2 = function(raw)
		local X, Y = raw.X, raw.Y

		return "<XS>"
			.. X.Scale
			.. "</XS><XO>"
			.. X.Offset
			.. "</XO><YS>"
			.. Y.Scale
			.. "</YS><YO>"
			.. Y.Offset
			.. "</YO>"
	end,
	Vector2 = function(raw)
		return XML_Descriptors.__VECTOR(raw.X, raw.Y)
	end,
	Vector2int16 = nil,
	Vector3 = function(raw)
		return XML_Descriptors.__VECTOR(raw.X, raw.Y, raw.Z)
	end,
	Vector3int16 = nil,
	bool = function(raw)
		return raw and "true" or "false"
	end,
	double = nil,
	float = nil,
	int = nil,
	int64 = nil,
	string = function(raw)
		return (raw == nil or raw == "") and ""
			or string_find(raw, "]]>") and string.gsub(raw, ESCAPES_PATTERN, ESCAPES)
			or XML_Descriptors.__CDATA(string.gsub(raw, "\0", ""))
	end,
}

do
	XML_Descriptors.NumberSequence = XML_Descriptors.__construct_Sequence(XML_Descriptors.NumberSequenceKeypoint)
	XML_Descriptors.ColorSequence = XML_Descriptors.__construct_Sequence(XML_Descriptors.ColorSequenceKeypoint)
end

for descriptorName, redirectName in
	{
		NetAssetRef = "SharedString",
		Vector2int16 = "Vector2",
		Vector3int16 = "Vector3",
		double = "__NORMALIZE_NUMBER",
		float = "__NORMALIZE_NUMBER",
		int = "__NORMALIZE_NUMBER",
		int64 = "__NORMALIZE_NUMBER",
	}
do
	XML_Descriptors[descriptorName] = XML_Descriptors[redirectName]
end

if CLIENT_VERSION < math.huge then
	XML_Descriptors.Content = XML_Descriptors.ContentId
end

local ClassList
do
	local ClassPropertyExceptions = {
		Whitelist = {
			MeshPart = ArrayToDict({ "CollisionFidelity" }),
			PartOperation = ArrayToDict({ "CollisionFidelity" }),
			TriangleMeshPart = ArrayToDict({ "CollisionFidelity" }),
		},
		Blacklist = {
			LuaSourceContainer = ArrayToDict({ "ScriptGuid" }),
			Instance = ArrayToDict({ "UniqueId", "HistoryId" }),
		},
	}

	local function AttributesSerialize(attrs)
		local attrs_n = 0
		local buffer_size = 4
		local attrs_sorted = {}
		local attrs_formatted = table.clone(attrs)
		for attr, val in attrs do
			attrs_n += 1
			attrs_sorted[attrs_n] = attr

			local Type = typeof(val)

			local Descriptor = Binary_Descriptors[Type]
			local attr_size

			attrs_formatted[attr], attr_size = Descriptor(val)

			buffer_size += 5 + #attr + attr_size
		end

		table.sort(attrs_sorted)

		local b = buffer.create(buffer_size)

		buffer.writeu32(b, 0, attrs_n)

		local string__descriptor = Binary_Descriptors.string
		local offset = 4
		for _, attr in attrs_sorted do
			local b_Name, Name_size = string__descriptor(attr)

			buffer.copy(b, offset, b_Name)
			offset += Name_size

			buffer.writeu8(b, offset, attr_Type_IDs[typeof(attrs[attr])])
			offset += 1

			local bb = attrs_formatted[attr]

			buffer.copy(b, offset, bb)
			offset += buffer.len(bb)
		end

		return buffer.tostring(b)
	end

	local function AttenuationSerialize(attenuations)
		if not next(attenuations) then
			return "\0"
		end

		local attenuations_n = 0

		local attenuations_sorted = {}

		for key in attenuations do
			attenuations_n += 1
			attenuations_sorted[attenuations_n] = key
		end

		table.sort(attenuations_sorted)

		local b = buffer.create(1 + attenuations_n * 8)

		local offset = 1
		for _, key in attenuations_sorted do
			buffer.writef32(b, offset, key)
			offset += 4
			buffer.writef32(b, offset, attenuations[key])
			offset += 4
		end

		return buffer.tostring(b)
	end

	local NotScriptableFixes = {
		Instance = {
			AttributesSerialize = function(instance)
				local attrs = instance:GetAttributes()

				if not next(attrs) then
					return ""
				end

				return AttributesSerialize(attrs)
			end,
			DefinesCapabilities = "Sandboxed",
			Tags = function(instance)
				local tags = instance:GetTags()

				if #tags == 0 then
					return ""
				end

				return table.concat(tags, "\0")
			end,
		},
		Path2D = {
			PropertiesSerialize = function(instance)
				local control_points = instance:GetControlPoints()
				local control_points_n = #control_points

				if control_points_n == 0 then
					return "\0\0\0\0"
				end

				local b = buffer.create(4 + control_points_n * 49)
				buffer.writeu32(b, 0, control_points_n)

				local TypeID_Path2DControlPoint = attr_Type_IDs["Path2DControlPoint"]
				local offset = 4
				for i, point in control_points do
					local buf = Binary_Descriptors.Path2DControlPoint(point)

					buffer.writeu8(b, offset, TypeID_Path2DControlPoint)
					offset += 1

					buffer.copy(b, offset, buf)
					offset += 48
				end

				return buffer.tostring(b)
			end,
		},
		StyleRule = {
			PropertiesSerialize = function(instance)
				local props = instance:GetProperties()

				if not next(props) then
					return "\0\0\0\0"
				end

				return AttributesSerialize(props)
			end,
		},
		StyleQuery = {
			ConditionsSerialize = function(instance)
				local props = instance:GetConditions()

				if not next(props) then
					return "\0\0\0\0"
				end

				return AttributesSerialize(props)
			end,
		},
		MarkerCurve = {
			ValuesAndTimes = function(instance)
				local markers = instance:GetMarkers()
				local markers_n = #markers

				if markers_n == 0 then
					return "\2\0\0\0\0\0\0\0\1\0\0\0\0\0\0\0"
				end

				local strings_size = 0
				for i, marker in markers do
					strings_size += #marker.Value + 1
				end

				local b = buffer.create(8 + strings_size + 8 + (markers_n * 4))

				buffer.writeu32(b, 0, 2)
				buffer.writeu32(b, 4, markers_n)

				local offset = 8
				for i, marker in markers do
					local value = marker.Value
					buffer.writestring(b, offset, value)
					offset += #value + 1
				end

				buffer.writeu32(b, offset, 1)
				offset += 4
				buffer.writeu32(b, offset, markers_n)
				offset += 4

				for i, marker in markers do
					local scaled_time = math.round(marker.Time * 2400)
					buffer.writeu32(b, offset, scaled_time)
					offset += 4
				end

				return buffer.tostring(b)
			end,
		},
		AudioEmitter = {
			AngleAttenuation = function(instance)
				return AttenuationSerialize(instance:GetAngleAttenuation())
			end,
			DistanceAttenuation = function(instance)
				return AttenuationSerialize(instance:GetDistanceAttenuation())
			end,
		},
		AudioListener = {
			AngleAttenuation = function(instance)
				return AttenuationSerialize(instance:GetAngleAttenuation())
			end,
			DistanceAttenuation = function(instance)
				return AttenuationSerialize(instance:GetDistanceAttenuation())
			end,
		},
		BallSocketConstraint = { MaxFrictionTorqueXml = "MaxFrictionTorque" },
		BasePart = {
			Color3uint8 = "Color",
			MaterialVariantSerialized = "MaterialVariant",
			size = "Size",
		},
		DoubleConstrainedValue = { value = "Value" },
		IntConstrainedValue = { value = "Value" },
		Terrain = {
			AcquisitionMethod = "LastUsedModificationMethod",
			MaterialColors = function(instance)
				local TERRAIN_MATERIAL_COLORS = {
					Enum.Material.Grass,
					Enum.Material.Slate,
					Enum.Material.Concrete,
					Enum.Material.Brick,
					Enum.Material.Sand,
					Enum.Material.WoodPlanks,
					Enum.Material.Rock,
					Enum.Material.Glacier,
					Enum.Material.Snow,
					Enum.Material.Sandstone,
					Enum.Material.Mud,
					Enum.Material.Basalt,
					Enum.Material.Ground,
					Enum.Material.CrackedLava,
					Enum.Material.Asphalt,
					Enum.Material.Cobblestone,
					Enum.Material.Ice,
					Enum.Material.LeafyGrass,
					Enum.Material.Salt,
					Enum.Material.Limestone,
					Enum.Material.Pavement,
				}

				local b = buffer.create(69)
				local offset = 6

				local RGB_components = { "R", "G", "B" }

				for _, material in TERRAIN_MATERIAL_COLORS do
					local color = instance:GetMaterialColor(material)
					for _, component in RGB_components do
						buffer.writeu8(b, offset, math.floor(color[component] * 255))
						offset += 1
					end
				end

				return buffer.tostring(b)
			end,
		},
		TriangleMeshPart = {
			FluidFidelityInternal = "FluidFidelity",
		},
		MeshPart = { InitialSize = "MeshSize" },
		PartOperation = { InitialSize = "MeshSize" },
		Part = { shape = "Shape" },
		TrussPart = { style = "Style" },
		FormFactorPart = {
			formFactorRaw = "FormFactor",
		},
		Fire = { heat_xml = "Heat", size_xml = "Size" },
		Humanoid = { Health_XML = "Health" },
		HumanoidDescription = {
			EmotesDataInternal = function(instance)
				local emotes_data = ""
				for name, ids in instance:GetEmotes() do
					emotes_data ..= name .. "^" .. table.concat(ids, "^") .. "^\\"
				end
				return emotes_data
			end,
			EquippedEmotesDataInternal = function(instance)
				local equipped_emotes_data = ""
				for _, emote in instance:GetEquippedEmotes() do
					equipped_emotes_data ..= emote.Slot .. "^" .. emote.Name .. "\\"
				end
				return equipped_emotes_data
			end,
		},
		LocalizationTable = {
			Contents = function(instance)
				return instance:GetContents()
			end,
		},
		MaterialService = { Use2022MaterialsXml = "Use2022Materials" },
		Model = {
			ScaleFactor = function(instance)
				return instance:GetScale()
			end,
			WorldPivotData = "WorldPivot",
		},
		PackageLink = { PackageIdSerialize = "PackageId", VersionIdSerialize = "VersionNumber" },
		Players = { MaxPlayersInternal = "MaxPlayers", PreferredPlayersInternal = "PreferredPlayers" },
		StarterPlayer = { AvatarJointUpgrade_Serialized = "AvatarJointUpgrade" },
		Smoke = { size_xml = "Size", opacity_xml = "Opacity", riseVelocity_xml = "RiseVelocity" },
		Sound = {
			xmlRead_MaxDistance_3 = "RollOffMaxDistance",
		},
		WeldConstraint = {
			Part0Internal = "Part0",
			Part1Internal = "Part1",
		},
		Workspace = {
			CollisionGroupData = function()
				local collision_groups = game:GetService("PhysicsService"):GetRegisteredCollisionGroups()

				local col_groups_n = #collision_groups

				if col_groups_n == 0 then
					return "\1\0"
				end

				local buffer_size = 2

				for _, group in collision_groups do
					buffer_size += 7 + #group.name
				end

				local b = buffer.create(buffer_size)

				buffer.writeu8(b, 0, 1)
				buffer.writeu8(b, 1, col_groups_n)

				local TypeID_int32 = attr_Type_IDs["int32"]
				local offset = 2
				for i, group in collision_groups do
					local name, id, mask = group.name, i - 1, group.mask
					local name_len = #name

					buffer.writeu8(b, offset, id)
					offset += 1

					buffer.writeu8(b, offset, TypeID_int32)
					offset += 1

					buffer.writei32(b, offset, mask)
					offset += 4

					buffer.writeu8(b, offset, name_len)
					offset += 1
					buffer.writestring(b, offset, name)
					offset += name_len
				end

				return buffer.tostring(b)
			end,
		},
	}

	local function FetchAPI()
		local API_Dump

		local ok, err = pcall(function()
			if EXECUTOR_NAME == "Velocity" then
				return
			end

			local CLIENT_VERSION_str = tostring(CLIENT_VERSION)
			local ok, result = pcall(readfile, CLIENT_VERSION_str)
			if
				ok
				and result
				and result ~= ""
				and pcall(service.HttpService.JSONDecode, service.HttpService, result)
			then
				API_Dump = result
				return
			end

			local matching_versions, is_matched = {}

			local DeployHistory = string.split(game:HttpGet("https://setup.rbxcdn.com/DeployHistory.txt", true), "\n")
			for i = #DeployHistory, 1, -1 do
				local line = DeployHistory[i]

				local file_version = string.match(line, "file version: ([%d, ]+)")
				if file_version then
					if string.split(file_version, ", ")[2] == CLIENT_VERSION_str then
						is_matched = true

						local version_hash = string.match(line, "(version%-[^%s]+)")
						if version_hash then
							matching_versions[version_hash] = true
						end
					elseif is_matched then
						break
					end
				end
			end

			for version_hash in matching_versions do
				ok, result = pcall(
					game.HttpGet,
					game,
					"https://setup.rbxcdn.com/" .. version_hash .. "-Full-API-Dump.json",
					true
				)
				if ok then
					local o, r = pcall(service.HttpService.JSONDecode, service.HttpService, result)
					if o then
						API_Dump = service.HttpService:JSONEncode(r.Classes)
						break
					end
				end
			end

			writefile(CLIENT_VERSION_str, API_Dump)
		end)

		if not ok or not API_Dump then
			warn("[DEBUG] Failed to get " .. version() .. " version API Dump, trying latest..")
			warn("[DEBUG]", err)
			API_Dump = service.HttpService:JSONEncode(
				service.HttpService:JSONDecode(
					game:HttpGet(
						"https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/Mini-API-Dump.json",
						true
					)
				).Classes
			)
		end

		local classList = {}

		local ClassesWhitelist, ClassesBlacklist = ClassPropertyExceptions.Whitelist, ClassPropertyExceptions.Blacklist

		for _, API_Class in service.HttpService:JSONDecode(API_Dump) do
			local ClassProperties, ClassProperties_size = {}, 1
			local Class = {
				Properties = ClassProperties,
				Superclass = API_Class.Superclass,
			}

			local ClassTags = API_Class.Tags
			local ClassName = API_Class.Name

			if ClassTags then
				Class.Tags = ArrayToDict(ClassTags, nil, nil, "string")
			end

			local NotScriptableFixClass = NotScriptableFixes[ClassName]

			local ClassWhitelist, ClassBlacklist = ClassesWhitelist[ClassName], ClassesBlacklist[ClassName]

			for _, Member in API_Class.Members do
				if Member.MemberType == "Property" then
					local Serialization = Member.Serialization

					if Serialization.CanLoad then
						local PropertyName = Member.Name
						if
							(Serialization.CanSave or ClassWhitelist and ClassWhitelist[PropertyName])
							and not (ClassBlacklist and ClassBlacklist[PropertyName])
						then
							local MemberTags = Member.Tags

							local ValueType = Member.ValueType
							local ValueType_Name = ValueType.Name

							if 645 <= CLIENT_VERSION and ValueType_Name == "Content" then
								continue
							end

							local Special, PreferredDescriptorName

							if MemberTags then
								for _, tag in MemberTags do
									if type(tag) == "table" then
										PreferredDescriptorName = tag.PreferredDescriptorName
										if PreferredDescriptorName and Special then
											break
										end
									elseif tag == "NotScriptable" then
										Special = true
										if PreferredDescriptorName then
											break
										end
									end
								end
							end

							local Property = {
								Name = PropertyName,
								Category = ValueType.Category,
								ValueType = ValueType_Name,

								Special = Special,

								CanRead = nil,
							}

							if string.sub(ValueType_Name, 1, 8) == "Optional" then
								Property.Optional = string.sub(ValueType_Name, 9)
							end

							if NotScriptableFixClass then
								local NotScriptableFix = NotScriptableFixClass[PropertyName]
								if NotScriptableFix then
									Property.Fallback = type(NotScriptableFix) == "function" and NotScriptableFix
										or PreferredDescriptorName and function(instance)
											local o, r = pcall(index, instance, PreferredDescriptorName)
											if o then
												return r
											end
											return instance[NotScriptableFix]
										end
										or function(instance)
											return instance[NotScriptableFix]
										end
								end
							elseif PreferredDescriptorName then
								Property.Fallback = function(instance)
									return instance[PreferredDescriptorName]
								end
							end
							ClassProperties[ClassProperties_size] = Property
							ClassProperties_size += 1
						end
					end
				end
			end

			classList[ClassName] = Class
		end

		return classList
	end

	local ok, result = pcall(FetchAPI)
	if ok then
		ClassList = result
	else
		warn("Failed to load the API Dump")
		warn(result)
		return
	end
end

local GLOBAL_ENV = getgenv and getgenv() or _G or shared

local function synsaveinstance(CustomOptions, CustomOptions2)
	print("[USSI] synsaveinstance called")  -- ДЕБАГ 1
	if GLOBAL_ENV.USSI then
		return
	end
	GLOBAL_ENV.USSI = true
    	print("[USSI] first guard passed")  -- ДЕБАГ 2
	
	do
		local setthreadidentity = global_container.setthreadidentity
		if setthreadidentity then
			pcall(setthreadidentity, 8)
		end
	end

	local currentstr, currentsize, totalsize, chunks = "", 0, 0, table.create(1)
	local savebuffer, savebuffer_size = {}, 1
	local header = '<!-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw --><roblox version="4">'
	local StatusText

	local function construct_TimeoutHandler(timeout, f, timeout_ret)
		if timeout < 0 then
			return function(script)
				return pcall(f, script)
			end
		end
		
		return function(script)
			local thread = coroutine.running()
			local completed = false
			
			local timeoutThread = task.delay(timeout, function()
				if not completed then
					completed = true
					task.spawn(function()
						coroutine.resume(thread, false, timeout_ret or "Timeout")
					end)
				end
			end)
			
			task.spawn(function()
				local ok, output = pcall(f, script)
				
				if not completed then
					completed = true
					task.cancel(timeoutThread)
					
					while coroutine.status(thread) ~= "suspended" do
						task.wait()
					end
					
					coroutine.resume(thread, ok, output)
				end
			end)
			
			return coroutine.yield()
		end
	end

	local OPTIONS = {
		mode = "optimized",
		noscripts = false,
		scriptcache = true,
		timeout = 10,
		__DEBUG_MODE = false,

		Callback = false,

		DecompileJobless = false,
		DecompileIgnore = {
			"TextChatService",
			ModuleScript = nil,
		},
		IgnoreDefaultPlayerScripts = EXECUTOR_NAME ~= "Wave",
		SaveBytecode = false,

		IgnoreProperties = {},

		IgnoreList = { "CoreGui", "CorePackages" },

		ExtraInstances = {},
		NilInstances = false,
		NilInstancesFixes = {},

		SaveCacheInterval = 0x1600 * 10,
		ShowStatus = true,
		SafeMode = false,
		ShutdownWhenDone = false,
		AntiIdle = true,
		Anonymous = false,
		ReadMe = true,
		FilePath = false,
		Object = false,
		IsModel = false,

		IgnoreDefaultProperties = true,
		IgnoreNotArchivable = true,
		IgnorePropertiesOfNotScriptsOnScriptsMode = false,
		IgnoreSpecialProperties = ArrayToDict({ "Fluxus", "Delta", "Solara" })[EXECUTOR_NAME] or false,

		IsolateLocalPlayer = false,
		IsolateLocalPlayerCharacter = false,
		IsolatePlayers = false,
		IsolateStarterPlayer = false,
		RemovePlayerCharacters = true,

		SaveNotCreatable = false,
		NotCreatableFixes = {
			"",
			"AdvancedDragger",
			"AnimationTrack",
			"Dragger",
			"Player",
			"PlayerGui",
			"PlayerMouse",
			"PlayerScripts",
			"ScreenshotHud",
			"StudioData",
			"TextChatMessage",
			"TextSource",
			"TouchTransmitter",
			"Translator",
			CloudLocalizationTable = "LocalizationTable",
		},

		IgnoreSharedStrings = EXECUTOR_NAME ~= "Wave",
		SharedStringOverwrite = false,
		TreatUnionsAsParts = EXECUTOR_NAME == "Solara",
		AlternativeWritefile = not ArrayToDict({ "WRD", "Xeno", "Zorara" })[EXECUTOR_NAME],

		OptionsAliases = {
			DecompileTimeout = "timeout",
			FileName = "FilePath",
			IgnoreArchivable = "IgnoreNotArchivable",
			IgnoreDefaultProps = "IgnoreDefaultProperties",
			SaveNonCreatable = "SaveNotCreatable",
			SavePlayers = "IsolatePlayers",
		},
	}

	local OPTIONS_lowercase, CustomOptions_valid = {}, {}
	for option_name in OPTIONS do
		local option_name_lowercase = string.lower(option_name)
		if OPTIONS_lowercase[option_name_lowercase] then
			warn("DUPLICATE OPTION", option_name)
		else
			OPTIONS_lowercase[option_name_lowercase] = option_name
		end
	end
	for option_alias, option_name in OPTIONS.OptionsAliases do
		local option_name_lowercase = string.lower(option_alias)
		if OPTIONS_lowercase[option_name_lowercase] then
			warn("DUPLICATE ALIAS", option_alias)
		else
			OPTIONS_lowercase[option_name_lowercase] = option_name
		end
	end

	do
		local function construct_NilinstanceFix(Name, ClassName, Separate)
			return function(instance, instancePropertyOverrides)
				local Exists

				if not Separate then
					Exists = OPTIONS.NilInstancesFixes[Name]
				end

				local Fix

				local DoesntExist = not Exists
				if DoesntExist then
					Fix = Instance.new(ClassName)
					if not Separate then
						OPTIONS.NilInstancesFixes[Name] = Fix
					end

					instancePropertyOverrides[Fix] =
						{ __SaveSpecific = true, __Children = { instance }, Properties = { Name = Name } }
				else
					Fix = Exists
					table.insert(instancePropertyOverrides[Fix].__Children, instance)
				end

				if DoesntExist then
					return Fix
				end
			end
		end

		OPTIONS.NilInstancesFixes.Animator = construct_NilinstanceFix(
			"Animator has to be placed under Humanoid or AnimationController",
			"AnimationController"
		)
		OPTIONS.NilInstancesFixes.AdPortal = construct_NilinstanceFix("AdPortal must be parented to a Part", "Part")
		OPTIONS.NilInstancesFixes.Attachment =
			construct_NilinstanceFix("Attachments must be parented to a BasePart or another Attachment", "Part")
		OPTIONS.NilInstancesFixes.BaseWrap =
			construct_NilinstanceFix("BaseWrap must be parented to a MeshPart", "MeshPart")
		OPTIONS.NilInstancesFixes.PackageLink =
			construct_NilinstanceFix("Package already has a PackageLink", "Folder", true)

		if CustomOptions2 and type(CustomOptions2) == "table" then
			local tmp = CustomOptions
			local Type = typeof(tmp)
			CustomOptions = CustomOptions2
			if Type == "Instance" then
				CustomOptions.Object = tmp
			elseif Type == "table" and typeof(tmp[1]) == "Instance" then
				CustomOptions.ExtraInstances = tmp
				OPTIONS.IsModel = true
			end
		end

		local Type = typeof(CustomOptions)

		if Type == "table" then
			if typeof(CustomOptions[1]) == "Instance" then
				OPTIONS.mode = "invalidmode"
				OPTIONS.ExtraInstances = CustomOptions
				OPTIONS.IsModel = true
				CustomOptions = {}
			else
				for key, value in CustomOptions do
					local option = OPTIONS_lowercase[string.lower(key)]

					if option then
						OPTIONS[option] = value
						CustomOptions_valid[option] = true
					end
				end
				local Decompile = CustomOptions.Decompile
				if Decompile ~= nil then
					OPTIONS.noscripts = not Decompile
				end
				local SavePlayerCharacters = CustomOptions.SavePlayerCharacters
				if SavePlayerCharacters ~= nil then
					OPTIONS.RemovePlayerCharacters = not SavePlayerCharacters
				end
				local RemovePlayers = CustomOptions.RemovePlayers
				if RemovePlayers ~= nil then
					OPTIONS.IsolatePlayers = not RemovePlayers
				end
			end
		elseif Type == "Instance" then
			OPTIONS.mode = "invalidmode"
			OPTIONS.Object = CustomOptions
			CustomOptions = {}
		else
			CustomOptions = {}
		end
	end

	local InstancesOverrides = {}

	local DecompileIgnore = ArrayToDict(OPTIONS.DecompileIgnore, true)
	local IgnoreList = ArrayToDict(OPTIONS.IgnoreList, true)
	local IgnoreProperties = ArrayToDict(OPTIONS.IgnoreProperties)
	local NotCreatableFixes = ArrayToDict(OPTIONS.NotCreatableFixes, true, "Folder")

	local __DEBUG_MODE = OPTIONS.__DEBUG_MODE

	if __DEBUG_MODE and type(__DEBUG_MODE) ~= "function" then
		__DEBUG_MODE = warn
	end

	local FilePath = OPTIONS.FilePath
	local SaveCacheInterval = OPTIONS.SaveCacheInterval
	local ToSaveInstance = OPTIONS.Object
	local IsModel = OPTIONS.IsModel

	if ToSaveInstance and CustomOptions_valid.IsModel == nil then
		IsModel = true
	end

	local IgnoreDefaultProperties = OPTIONS.IgnoreDefaultProperties
	local IgnoreNotArchivable = not OPTIONS.IgnoreNotArchivable
	local IgnorePropertiesOfNotScriptsOnScriptsMode = OPTIONS.IgnorePropertiesOfNotScriptsOnScriptsMode

	local old_gethiddenproperty
	if OPTIONS.IgnoreSpecialProperties and gethiddenproperty then
		old_gethiddenproperty = gethiddenproperty
		gethiddenproperty = nil
	end

	local SaveNotCreatable = OPTIONS.SaveNotCreatable
	local TreatUnionsAsParts = OPTIONS.TreatUnionsAsParts

	local DecompileJobless = OPTIONS.DecompileJobless
	if DecompileJobless then
		OPTIONS.scriptcache = true
	end
	local ScriptCache = OPTIONS.scriptcache and getscriptbytecode

	local Timeout = OPTIONS.timeout

	local IgnoreSharedStrings = OPTIONS.IgnoreSharedStrings
	local SharedStringOverwrite = OPTIONS.SharedStringOverwrite

	local ldeccache = GLOBAL_ENV.scriptcache

	local DecompileIgnoring, ToSaveList, ldecompile, placename, elapse_t, SaveNotCreatableWillBeEnabled, RecoveredScripts

	if OPTIONS.ReadMe then
		RecoveredScripts = {}
	end

	if ScriptCache and not ldeccache then
		ldeccache = {}
		GLOBAL_ENV.scriptcache = ldeccache
	end
    	local getbytecode
	if getscriptbytecode then
		local test_ok = pcall(function()
			local temp = Instance.new("LocalScript")
			getscriptbytecode(temp)
			temp:Destroy()
		end)
		
		if test_ok then
			getbytecode = construct_TimeoutHandler(3, getscriptbytecode)
		else
			if __DEBUG_MODE then
				__DEBUG_MODE("⚠️ getscriptbytecode exists but doesn't work")
			end
		end
	end

	local SaveBytecode
	if OPTIONS.SaveBytecode and getbytecode then
		SaveBytecode = function(script)
			local s, bytecode = getbytecode(script)

			if s and bytecode and bytecode ~= "" then
				return "-- Bytecode (Base64):\n-- " .. base64encode(bytecode) .. "\n\n"
			end
		end
	end

	do
		-- Берём встроенный decompile, если есть
		local Decompiler = decompile

		-- Если явно выключено через опции
		if OPTIONS.noscripts then
			ldecompile = function()
				return "-- Decompiling is disabled"
			end

		-- Если executor имеет встроенный decompile
		elseif typeof(Decompiler) == "function" then
			-- Оборачиваем его в timeout
			local decomp = construct_TimeoutHandler(Timeout, Decompiler, "Decompiler timed out")

			ldecompile = function(script)
				local bytecode

				if ScriptCache and getbytecode then
					local s
					s, bytecode = getbytecode(script)
					local cached

					if s then
						if not bytecode or bytecode == "" then
							return "-- The Script is Empty"
						end
						cached = ldeccache[bytecode]
					else
						bytecode = nil
					end

					if cached then
						if __DEBUG_MODE then
							__DEBUG_MODE("Found in Cache", script:GetFullName())
						end
						return cached
					end
				else
					if DecompileJobless then
						return "-- Not found in already decompiled ScriptCache"
					end
					task.wait()
				end

							-- вызов decompiler с timeout/GUI или напрямую
				local ok, result
				if type(run_with_loading) == "function" then
					ok, result = run_with_loading("Decompiling " .. script.Name, true, nil, decomp, script)
				else
					ok, result = pcall(decomp, script)
				end

				-- нормализуем результат в строку
				if type(result) ~= "string" then
					if result == nil then
						result = "Empty Output"
					else
						-- если какой-то другой тип (boolean, table, number) – приводим к строке
						result = tostring(result)
					end
				end

				local output
				if ok then
					-- иногда деобфускаторы/декомпиляторы могут вернуть \0
					result = string.gsub(result, "\0", "\\0")
					output = result
				else
					output = "--[[ Failed to decompile. Reason:\n" .. (result or "") .. "\n]]"
				end

				if ScriptCache and bytecode then
					ldeccache[bytecode] = output
					if __DEBUG_MODE then
						__DEBUG_MODE("Cached", script:GetFullName())
					end
				end

				return output
			end

		-- Если встроенного decompile нет, но есть getscriptbytecode
		elseif getbytecode then
			-- очень простой fallback: просто пишем инфу о байткоде
			ldecompile = function(script)
				local s, bytecode = getbytecode(script)
				if not s or not bytecode or bytecode == "" then
					return "-- Empty or unavailable bytecode"
				end

				local out = {
					"-- No builtin decompiler on this executor.",
					"-- Script: " .. script:GetFullName(),
					"-- Bytecode length: " .. #bytecode,
				}
				if base64encode then
					table.insert(out, "-- Bytecode (Base64):")
					table.insert(out, "-- " .. base64encode(bytecode))
				end

				return table.concat(out, "\n")
			end

		-- Вообще ничего нет — ни decompile, ни getscriptbytecode
		else
			ldecompile = function()
				return "-- Your Executor does NOT have a Decompiler"
			end
		end
	end
	local function GetLocalPlayer()
		return service.Players.LocalPlayer
			or service.Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
			or service.Players.LocalPlayer
	end

	local function filterLinkedSource(str)
		local o, r = pcall(service.HttpService.JSONDecode, service.HttpService, str)
		if o and r.errors then
			return
		end
		return true
	end

	local function replaceClassName(instance, InstanceName, ClassName)
		local InstanceOverride
		if InstanceName ~= ClassName then
			InstanceOverride = InstancesOverrides[instance]
			if not InstanceOverride then
				InstanceOverride = { Properties = { Name = "[" .. ClassName .. "] " .. InstanceName } }
				InstancesOverrides[instance] = InstanceOverride
			end
		end
		return InstanceOverride
	end

	local function filterPropVal(result, propertyName, category)
		return result == nil
			or result == "can't get value"
			or type(result) == "string"
				and (category == "Enum" or string_find(result, "Unable to get property " .. propertyName))
	end

	local __BREAK = "__BREAK" .. service.HttpService:GenerateGUID(false)

	local function ReadProperty(instance, property, propertyName, special, category, optional)
		local raw = __BREAK

		local InstanceOverride = InstancesOverrides[instance]
		if InstanceOverride then
			local PropertiesOverride = InstanceOverride.Properties
			if PropertiesOverride then
				local PropertyOverride = PropertiesOverride[propertyName]
				if PropertyOverride ~= nil then
					return PropertyOverride
				end
			end
		end

		local CanRead = property.CanRead

		if CanRead == false then
			return __BREAK
		end

		if special then
			if gethiddenproperty then
				local ok, result = pcall(gethiddenproperty, instance, propertyName)

				if ok then
					raw = result
				end

				if filterPropVal(raw, propertyName, category) then
					if result ~= nil or not optional then
						if __DEBUG_MODE then
							__DEBUG_MODE("Filtered", propertyName)
						end
						property.CanRead = false
					end

					return __BREAK
				end
			end
		else
			if CanRead then
				raw = instance[propertyName]
			else
				local ok, result = pcall(index, instance, propertyName)

				if ok then
					raw = result
				elseif gethiddenproperty then
					ok, result = pcall(gethiddenproperty, instance, propertyName)

					if ok then
						raw = result

						property.Special = true
					end
				end

				property.CanRead = ok

				if not ok or filterPropVal(raw, propertyName, category) then
					return __BREAK
				end
			end
		end

		return raw
	end

	local function ReturnItem(className, instance)
		return '<Item class="' .. className .. '" referent="' .. GetRef(instance) .. '"><Properties>'
	end

	local function ReturnProperty(tag, propertyName, value)
		return "<" .. tag .. ' name="' .. propertyName .. '">' .. value .. "</" .. tag .. ">"
	end

	local function ReturnValueAndTag(raw, valueType, descriptor)
		local value, tag = (descriptor or XML_Descriptors[valueType])(raw)

		return value, tag or valueType
	end

	local function InheritsFix(fixes, className, instance)
		local Fix = fixes[className]
		if Fix then
			return Fix
		elseif Fix == nil then
			for class_name, fix in fixes do
				if instance:IsA(class_name) then
					return fix
				end
			end
		end
	end

	local function GetInheritedProps(className)
		local prop_list = {}
		local layer = ClassList[className]
		while layer do
			local layer_props = layer.Properties
			table.move(layer_props, 1, #layer_props, #prop_list + 1, prop_list)

			layer = ClassList[layer.Superclass]
		end
		inherited_properties[className] = prop_list
		return prop_list
	end

	local CHUNK_LIMIT = 200 * 1024 * 1024
	
    ----------------------------------------------------------------

    local function get_size_format()
        local Size

        for i, unit in
            {
                "B",
                "KB",
                "MB",
                "GB",
                "TB",
            }
        do
            if totalsize < 0x400 ^ i then
                Size = math.floor(totalsize / (0x400 ^ (i - 1)) * 10) / 10 .. " " .. unit
                break
            end
        end

        return Size or "0 B"
    end

    local CHUNK_LIMIT = 200 * 1024 * 1024 -- 200MB

    local function save_cache(final)
        -- Склеиваем текущий буфер в строку
        local savestr = table.concat(savebuffer)
        currentstr ..= savestr

        -- Обновляем счётчики размеров
        local savestr_len = #savestr
        totalsize += savestr_len
        currentsize += savestr_len

        -- Очищаем буфер
        table.clear(savebuffer)
        savebuffer_size = 1

        -- Если текущий кусок превысил лимит или это финальный вызов —
        -- переносим его в общий список chunks
        if CHUNK_LIMIT < currentsize or final then
            table.insert(chunks, { size = currentsize, str = currentstr })
            currentstr, currentsize = "", 0
        end

        -- Обновляем GUI статуса
        if StatusText then
            StatusText.Text = "Saving.. Size: " .. get_size_format()
        end

        -- Ждём кадр, чтобы не фризануть клиент
        wait_for_render()
    end

	local function save_cache(final)
		local savestr = table.concat(savebuffer)
		currentstr ..= savestr

		local savestr_len = #savestr
		totalsize += savestr_len
		currentsize += savestr_len

		table.clear(savebuffer)
		savebuffer_size = 1

		if CHUNK_LIMIT < currentsize or final then
			table.insert(chunks, { size = currentsize, str = currentstr })
			currentstr, currentsize = "", 0
		end

		if StatusText then
			StatusText.Text = "Saving.. Size: " .. get_size_format()
		end
		wait_for_render()
	end

	local function save_specific(className, properties)
		local Ref = Instance.new(className)
		local Item = ReturnItem(Ref.ClassName, Ref)

		for propertyName, val in properties do
			local whitelisted, value, tag

			if "Source" == propertyName then
				tag = "ProtectedString"
				value = XML_Descriptors.__PROTECTEDSTRING(val)
				whitelisted = true
			elseif "Name" == propertyName then
				whitelisted = true
				value, tag = ReturnValueAndTag(val, "string")
			end

			if whitelisted then
				Item ..= ReturnProperty(tag, propertyName, value)
			end
		end
		Item ..= "</Properties>"
		return Item
	end

	local function get_size_format()
		local Size

		for i, unit in
			{
				"B",
				"KB",
				"MB",
				"GB",
				"TB",
			}
		do
			if totalsize < 0x400 ^ i then
				Size = math.floor(totalsize / (0x400 ^ (i - 1)) * 10) / 10 .. " " .. unit
				break
			end
		end

		return Size
	end

	local RunService = service.RunService
	local function wait_for_render()
		RunService.RenderStepped:Wait()
	end

	local Loading
	local function run_with_loading(text, keepStatus, waitForRender, taskFunction, ...)
		local previousStatus

		if StatusText then
			if keepStatus then
				previousStatus = StatusText.Text
			end
			Loading = task.spawn(function()
				local spinner_count = 0
				local chars = { "|", "/", "—", "\\" }
				local chars_size = #chars

				local function getLoadingText()
					spinner_count += 1

					if chars_size < spinner_count then
						spinner_count = 1
					end

					return chars[spinner_count]
				end

				text ..= " "

				while true do
					StatusText.Text = text .. getLoadingText()
					task.wait(0.25)
				end
			end)
			if waitForRender then
				wait_for_render()
			end
		end

		local result = { taskFunction(...) }

		if Loading then
			task.cancel(Loading)
			Loading = nil
			if previousStatus then
				StatusText.Text = previousStatus
			end
		end

		return unpack(result)
	end

	if ToSaveInstance == game then
		OPTIONS.mode = "full"
		ToSaveInstance = nil
		IsModel = nil
	end

	local function isLuaSourceContainer(instance)
		return instance:IsA("LuaSourceContainer")
	end

	do
		local mode = string.lower(OPTIONS.mode)
		local tmp = table.clone(OPTIONS.ExtraInstances)

		local PlaceName = game.PlaceId

		pcall(function()
			PlaceName ..= " " .. service.MarketplaceService:GetProductInfo(PlaceName).Name
		end)

		local function sanitizeFileName(str)
			return string.sub(string.gsub(string.gsub(string.gsub(str, "[^%w _]", ""), " +", " "), " +$", ""), 1, 240)
		end

		if ToSaveInstance then
			if mode == "optimized" then
				mode = "full"
			end

			for _, key in
				{
					"IsolateLocalPlayer",
					"IsolateLocalPlayerCharacter",
					"IsolatePlayers",
					"IsolateStarterPlayer",
					"NilInstances",
				}
			do
				if CustomOptions_valid[key] == nil then
					OPTIONS[key] = false
				end
			end
		end

		if IsModel then
			placename = (
				FilePath
				or sanitizeFileName("model " .. PlaceName .. " " .. (ToSaveInstance or tmp[1] or game):GetFullName())
			) .. ".rbxmx"
		else
			placename = (FilePath or sanitizeFileName("place " .. PlaceName)) .. ".rbxlx"
		end

		if GLOBAL_ENV[placename] then
			return
		end

		GLOBAL_ENV[placename] = true
		GLOBAL_ENV.USSI = nil
		if mode ~= "scripts" then
			IgnorePropertiesOfNotScriptsOnScriptsMode = nil
		end

		local TempRoot = ToSaveInstance or game

		if mode == "full" then
			if not ToSaveInstance then
				local Children = TempRoot:GetChildren()
				if 0 < #Children then
					local tmp_dict = ArrayToDict(tmp)
					for _, child in Children do
						if not tmp_dict[child] then
							table.insert(tmp, child)
						end
					end
				end
			end
		elseif mode == "optimized" then
			local tmp_dict = ArrayToDict(tmp)

			for _, serviceName in
				{
					"Workspace",
					"Players",
					"Lighting",
					"MaterialService",
					"ReplicatedFirst",
					"ReplicatedStorage",

					"ServerScriptService",
					"ServerStorage",

					"StarterGui",
					"StarterPack",
					"StarterPlayer",
					"Teams",
					"SoundService",
					"Chat",
					"TextChatService",

					"LocalizationService",
					"JointsService",
				}
			do
				local _service = game:FindService(serviceName)
				if _service and not tmp_dict[_service] then
					table.insert(tmp, _service)
				end
			end
		elseif mode == "scripts" then
			local unique = {}
			for _, instance in TempRoot:GetDescendants() do
				if isLuaSourceContainer(instance) then
					local Parent = instance.Parent
					while Parent and Parent ~= TempRoot do
						instance = instance.Parent
						Parent = instance.Parent
					end
					if Parent then
						unique[instance] = true
					end
				end
			end
			for instance in unique do
				table.insert(tmp, instance)
			end
		end

		ToSaveList = tmp

		if ToSaveInstance then
			table.insert(ToSaveList, 1, ToSaveInstance)
		end
	end

	local IsolateLocalPlayer = OPTIONS.IsolateLocalPlayer
	local IsolateLocalPlayerCharacter = OPTIONS.IsolateLocalPlayerCharacter
	local IsolatePlayers = OPTIONS.IsolatePlayers
	local IsolateStarterPlayer = OPTIONS.IsolateStarterPlayer
	local NilInstances = OPTIONS.NilInstances

	if NilInstances and enablenilinstances then
		enablenilinstances()
	end

	if OPTIONS.IgnoreDefaultPlayerScripts then
		local DecompileIgnore = OPTIONS.DecompileIgnore

		local default_scripts = ArrayToDict({
			ModuleScript = { "PlayerModule" },
			LocalScript = {
				"BubbleChat",
				"ChatScript",
				"PlayerScriptsLoader",
				"RbxCharacterSounds",
			},
		}, true)

		local function ignorePath(path)
			if path then
				for _, child in path:GetChildren() do
					local class_match = default_scripts[child.ClassName]
					if class_match then
						local name_match = class_match[child.Name]
						if name_match then
							table.insert(DecompileIgnore, child)
						end
					end
				end
			end
		end

		ignorePath(service.StarterPlayer:FindFirstChild("StarterPlayerScripts"))

		local LocalPlayer = service.Players.LocalPlayer
		if LocalPlayer then
			ignorePath(LocalPlayer:FindFirstChild("PlayerScripts"))
		end
	end
    	local function save_hierarchy(hierarchy)
		for _, instance in hierarchy do
			if IgnoreNotArchivable and not instance.Archivable then
				continue
			end

			local SkipEntirely = IgnoreList[instance]
			if SkipEntirely then
				continue
			end

			local ClassName = instance.ClassName
			local InstanceName = instance.Name

			do
				local OnIgnoredList = IgnoreList[ClassName]
				if OnIgnoredList and (OnIgnoredList == true or OnIgnoredList[InstanceName]) then
					continue
				end
			end

			if not DecompileIgnoring then
				DecompileIgnoring = DecompileIgnore[instance]

				if DecompileIgnoring == nil then
					local DecompileIgnored = DecompileIgnore[ClassName]
					if DecompileIgnored then
						DecompileIgnoring = DecompileIgnored == true or DecompileIgnored[InstanceName]
					end
				end

				if DecompileIgnoring then
					DecompileIgnoring = instance
				elseif DecompileIgnoring == false then
					DecompileIgnoring = 1
				end
			end

			local InstanceOverride, ClassNameOverride, ClassTagOverride

			do
				local Fix = NotCreatableFixes[ClassName]

				if Fix then
					if SaveNotCreatable then
						ClassName, InstanceOverride = Fix, replaceClassName(instance, InstanceName, ClassName)
					else
						continue
					end
				else
					if TreatUnionsAsParts and instance:IsA("PartOperation") then
						ClassName, InstanceOverride = "Part", replaceClassName(instance, InstanceName, ClassName)
						ClassNameOverride = "BasePart"
					elseif not ClassList[ClassName] then
						if __DEBUG_MODE then
							__DEBUG_MODE("Class not Found", ClassName)
						end

						ClassTagOverride = ClassName
						ClassName = "Folder"
					end
				end
			end

			if not InstanceOverride then
				InstanceOverride = InstancesOverrides[instance]
			end

			if InstanceOverride and InstanceOverride.__SaveSpecific then
				savebuffer[savebuffer_size] = save_specific(ClassName, InstanceOverride.Properties)
				savebuffer_size += 1
			else
				savebuffer[savebuffer_size] = ReturnItem(ClassTagOverride or ClassName, instance)
				savebuffer_size += 1
				if not (IgnorePropertiesOfNotScriptsOnScriptsMode and not isLuaSourceContainer(instance)) then
					local default_instance, new_def_inst

					if IgnoreDefaultProperties then
						default_instance = default_instances[ClassName]
						if not default_instance then
							local ClassTags = ClassList[ClassName].Tags
							if not (ClassTags and ClassTags.NotCreatable) then
								local ok, result = pcall(Instance.new, ClassName)

								if ok then
									new_def_inst = result

									default_instance = {}

									default_instances[ClassName] = default_instance
								elseif __DEBUG_MODE then
									__DEBUG_MODE("Unable to create default Instance x2", ClassName, result)
								end
							elseif __DEBUG_MODE then
								__DEBUG_MODE("Unable to create default Instance", ClassName)
							end
						end
					end
					local proplist
					do
						local class = ClassNameOverride or ClassName
						proplist = inherited_properties[class]
						if not proplist then
							proplist = GetInheritedProps(class)
							inherited_properties[class] = proplist
						end
					end
					for _, Property in proplist do
						local PropertyName = Property.Name

						if IgnoreProperties[PropertyName] then
							continue
						end

						local ValueType = Property.ValueType

						if IgnoreSharedStrings and ValueType == "SharedString" then
							continue
						end

						local Special, Category, Optional = Property.Special, Property.Category, Property.Optional

						local raw = ReadProperty(instance, Property, PropertyName, Special, Category, Optional)

						if raw == __BREAK then
							local ok, result = pcall(gethiddenproperty_fallback, instance, PropertyName)

							if result == nil and not Optional then
								ok = nil
							end

							if ok then
								raw = result
							else
								local Fallback = Property.Fallback

								if Fallback then
									ok, result = pcall(Fallback, instance)

									if ok then
										raw = result
									else
										if __DEBUG_MODE then
											__DEBUG_MODE("Fix Failed", PropertyName)
										end
										continue
									end
								else
									continue
								end
							end
						end

						if SharedStringOverwrite and ValueType == "BinaryString" then
							ValueType = "SharedString"
						end

						if
							default_instance
							and Property.CanRead ~= false
							and not Property.Special
							and not (PropertyName == "Source" and isLuaSourceContainer(instance))
						then
							if new_def_inst then
								default_instance[PropertyName] = index(new_def_inst, PropertyName)
							end
							if default_instance[PropertyName] == raw then
								continue
							end
						end

						local tag, value
						if Category == "Class" then
							tag = "Ref"
							if raw then
								if SaveNotCreatableWillBeEnabled then
									local Fix = NotCreatableFixes[raw.ClassName]
									if
										Fix
										and (
											PropertyName == "PlayerToHideFrom"
											or ValueType ~= "Instance" and ValueType ~= Fix
										)
									then
										continue
									end
								end

								value = GetRef(raw)
							else
								value = "null"
							end
						elseif Category == "Enum" then
							value, tag = XML_Descriptors.__ENUM(raw)
						else
							local Descriptor = XML_Descriptors[ValueType]

							if Descriptor then
								value, tag = ReturnValueAndTag(raw, ValueType, Descriptor)
							elseif "ProtectedString" == ValueType then
								tag = ValueType

								if PropertyName == "Source" then
									if DecompileIgnoring then
										if DecompileIgnoring == 1 then
											DecompileIgnoring = nil
										end
										value = "-- Ignored"
									else
										local should_decompile = true
										local LinkedSource
										local LinkedSource_Url = instance.LinkedSource
										local hasLinkedSource = LinkedSource_Url ~= ""
										local LinkedSource_type
										if hasLinkedSource then
											local Path = instance:GetFullName()
											if RecoveredScripts then
												table.insert(RecoveredScripts, Path)
											end

											LinkedSource = string.match(LinkedSource_Url, "%w+$")
											if LinkedSource then
												if ScriptCache then
													local cached = ldeccache[LinkedSource]

													if cached then
														value = cached
														should_decompile = nil
													end
												end
												if should_decompile then
													if DecompileJobless then
														value = "-- Not found in LinkedSource ScriptCache"
														should_decompile = nil
													end

													LinkedSource_type = string.find(LinkedSource, "%a") and "hash"
														or "id"

													local asset = LinkedSource_type .. "=" .. LinkedSource

													local ok, source = pcall(function()
														return game:HttpGet(
															"https://assetdelivery.roproxy.com/v1/asset/?" .. asset
														)
													end)

													if ok and filterLinkedSource(source) then
														if ScriptCache then
															ldeccache[LinkedSource] = source
														end

														value = source

														should_decompile = nil
													end
												end
											else
												warn(
													"FAILED TO EXTRACT ORIGINAL SCRIPT SOURCE (OPEN A GITHUB ISSUE): ",
													instance:GetFullName(),
													LinkedSource_Url
												)
											end
										end

										if should_decompile then
											local isLocalScript = instance:IsA("LocalScript")
											if
												isLocalScript and instance.RunContext == Enum.RunContext.Server
												or not isLocalScript
													and instance:IsA("Script")
													and instance.RunContext ~= Enum.RunContext.Client
											then
												value = "-- [FilteringEnabled] Server Scripts are IMPOSSIBLE to save"
											else
												value = ldecompile(instance)
												if SaveBytecode and getbytecode then
													local output = SaveBytecode(instance)
													if output then
														value = output .. value
													end
												end
											end
										end

										value = "-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw\n\n"
											.. (hasLinkedSource and "-- Original Source: https://assetdelivery.roblox.com/v1/asset/?" .. (LinkedSource_type or "id") .. "=" .. (LinkedSource or LinkedSource_Url) .. "\n\n" or "")
											.. value
									end
								end
								value = XML_Descriptors.__PROTECTEDSTRING(value)
							else
								if Optional then
									Descriptor = XML_Descriptors[Optional]

									if Descriptor then
										if raw == nil then
											continue
										else
											value, tag = ReturnValueAndTag(raw, ValueType, Descriptor)
										end
									end
								end
							end
						end

						if tag then
							savebuffer[savebuffer_size] = ReturnProperty(tag, PropertyName, value)
							savebuffer_size += 1
						else
							warn("UNSUPPORTED TYPE (OPEN A GITHUB ISSUE): ", ValueType, ClassName, PropertyName)
						end
					end
				end
				savebuffer[savebuffer_size] = "</Properties>"
				savebuffer_size += 1

				if SaveCacheInterval < savebuffer_size then
					save_cache()
				end
			end

			if SkipEntirely ~= false then
				local Children = InstanceOverride and InstanceOverride.__Children or instance:GetChildren()

				if #Children ~= 0 then
					save_hierarchy(Children)
				end
			end

			if DecompileIgnoring and DecompileIgnoring == instance then
				DecompileIgnoring = nil
			end

			savebuffer[savebuffer_size] = "</Item>"
			savebuffer_size += 1
		end
	end

	local function save_extra(name, hierarchy, customClassName, source)
		savebuffer[savebuffer_size] = save_specific((customClassName or "Folder"), { Name = name, Source = source })
		savebuffer_size += 1
		if hierarchy then
			save_hierarchy(hierarchy)
		end
		savebuffer[savebuffer_size] = "</Item>"
		savebuffer_size += 1
	end

	local function save_game()
		do
			if IsModel then
				header ..= '<Meta name="ExplicitAutoJoints">true</Meta>'
			end

			writefile(placename, header)
		end

		SaveNotCreatableWillBeEnabled = SaveNotCreatable
			or (IsolateLocalPlayer or IsolateLocalPlayerCharacter) and IsolateLocalPlayer
			or IsolatePlayers
			or NilInstances and global_container.getnilinstances

		save_hierarchy(ToSaveList)

		if IsolateLocalPlayer or IsolateLocalPlayerCharacter then
			local LocalPlayer = service.Players.LocalPlayer
			if LocalPlayer then
				if IsolateLocalPlayer then
					SaveNotCreatable = true
					save_extra("LocalPlayer", LocalPlayer:GetChildren())
				end
				if IsolateLocalPlayerCharacter then
					local LocalPlayerCharacter = LocalPlayer.Character
					if LocalPlayerCharacter then
						save_extra("LocalPlayer Character", LocalPlayerCharacter:GetChildren())
					end
				end
			end
		end

		if IsolateStarterPlayer then
			save_extra("StarterPlayer", service.StarterPlayer:GetChildren())
		end

		if IsolatePlayers then
			SaveNotCreatable = true
			save_extra("Players", service.Players:GetChildren())
		end

		if NilInstances and global_container.getnilinstances then
			local nil_instances, nil_instances_size = {}, 1

			local NilInstancesFixes = OPTIONS.NilInstancesFixes

			for _, instance in global_container.getnilinstances() do
				if instance == game then
					instance = nil
				else
					local ClassName = instance.ClassName

					local Fix = InheritsFix(NilInstancesFixes, ClassName, instance)

					if Fix then
						instance = Fix(instance, InstancesOverrides)
					end

					local Class = ClassList[ClassName]
					if Class then
						local ClassTags = Class.Tags
						if ClassTags and ClassTags.Service then
							instance = nil
						end
					end
				end
				if instance then
					nil_instances[nil_instances_size] = instance
					nil_instances_size += 1
				end
			end
			SaveNotCreatable = true
			save_extra("Nil Instances", nil_instances)
		end

		if OPTIONS.ReadMe then
			save_extra(
				"README",
				nil,
				"Script",
				"--[[\n"
					.. (#RecoveredScripts ~= 0 and "\t\tIMPORTANT: Original Source of these Scripts was Recovered: " .. service.HttpService:JSONEncode(
						RecoveredScripts
					) .. "\n" or "")
					.. [[
		Thank you for using UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw.

		If you didn't save in Binary (rbxl) - it's recommended to save the game right away to take advantage of the binary format & to preserve values of certain properties if you used IgnoreDefaultProperties setting (as they might change in the future).
		You can do that by going to FILE -> Save to File As -> Make sure File Name ends with .rbxl -> Save

		ServerStorage, ServerScriptService and Server Scripts are IMPOSSIBLE to save because of FilteringEnabled.

		If your player cannot spawn into the game, please move the scripts in StarterPlayer somewhere else or delete them. Then run `game:GetService("Players").CharacterAutoLoads = true`.
		And use "Play Here" to start game instead of "Play" to spawn your Character where your Camera currently is.

		If the chat system does not work, please use the explorer and delete everything inside the TextChatService/Chat service(s). 
		Or run `game:GetService("Chat"):ClearAllChildren() game:GetService("TextChatService"):ClearAllChildren()`
				
		If Union and MeshPart collisions don't work, run the script below in the Studio Command Bar:
				
				
		local C = game:GetService("CoreGui")
		local D = Enum.CollisionFidelity.Default
				
		for _, v in game:GetDescendants() do
			if v:IsA("TriangleMeshPart") and not v:IsDescendantOf(C) then
				v.CollisionFidelity = D
			end
		end
		print("Done")
				
		If you can't move the Camera, run this script in the Studio Command Bar:
			
		workspace.CurrentCamera.CameraType = Enum.CameraType.Fixed
		
		Or Destroy the Camera.

		This file was generated with the following settings:
		]]
					.. service.HttpService:JSONEncode(OPTIONS)
					.. "\n\n\t\tElapsed time: "
					.. os.clock() - elapse_t
					.. " PlaceId: "
					.. game.PlaceId
					.. " PlaceVersion: "
					.. game.PlaceVersion
					.. " Client Version: "
					.. version()
					.. " Executor: "
					.. (identify_executor and table.concat({ identify_executor() }, " ") or "Unknown")
					.. "\n]]"
			)
		end
		do
			local tmp = { "<SharedStrings>" }
			for identifier, value in SharedStrings.data do
				table.insert(tmp, '<SharedString md5="' .. identifier .. '">' .. value .. "</SharedString>")
			end

			if 1 < #tmp then
				savebuffer[savebuffer_size] = table.concat(tmp)
				savebuffer_size += 1
				savebuffer[savebuffer_size] = "</SharedStrings>"
				savebuffer_size += 1
			end
		end

		savebuffer[savebuffer_size] =
			"</roblox><!-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw -->"
		savebuffer_size += 1
		save_cache(true)

		if OPTIONS.Anonymous then
			local LocalPlayer = service.Players.LocalPlayer
			if LocalPlayer then
				local function gsubCaseInsensitive(input, search, replacement)
					local inputLower = string.lower(input)

					search = string.lower(search)

					local lastFinish = 0
					local subStrings = {}
					local search_len = #search
					local input_len = #input
					while search_len <= input_len - lastFinish do
						local init = lastFinish + 1

						local start, finish = string.find(inputLower, search, init, true)

						if start == nil then
							break
						end

						table.insert(subStrings, string.sub(input, init, start - 1))

						lastFinish = finish
					end

					if lastFinish == 0 then
						return input
					end

					table.insert(subStrings, string.sub(input, lastFinish + 1))

					return table.concat(subStrings, replacement)
				end

				local Anonymous = type(OPTIONS.Anonymous) == "table" and OPTIONS.Anonymous
					or { UserId = "1", Name = "Roblox" }

				for _, chunk in chunks do
					chunk.str = gsubCaseInsensitive(
						string.gsub(chunk.str, LocalPlayer.UserId, Anonymous.UserId),
						LocalPlayer.Name,
						Anonymous.Name
					)
				end
			end
		end

		local Callback = OPTIONS.Callback
		if Callback then
			local totalstr = header
			for _, chunk in chunks do
				totalstr ..= chunk.str
			end
			Callback(totalstr, chunks, totalsize)
		elseif OPTIONS.AlternativeWritefile and appendfile then
			local function safeAppend(filename, content)
				local ok = false
				if appendfile then
					ok = pcall(appendfile, filename, content)
				end
				if not ok then
					local existing = ""
					if isfile and isfile(filename) then
						existing = readfile(filename)
					end
					writefile(filename, existing .. content)
				end
			end

			local SEGMENT_SIZE = 4145728

			local totallen, currentlen = math.ceil(totalsize / SEGMENT_SIZE), 1

			for _, chunk in chunks do
				local length = math.ceil(chunk.size / SEGMENT_SIZE)
				for i = 1, length do
					local savestr = string.sub(chunk.str, (i - 1) * SEGMENT_SIZE + 1, i * SEGMENT_SIZE)

					run_with_loading(
						"Writing to File " .. math.round(currentlen / totallen * 100) .. "% (Depends on Exec)",
						nil,
						true,
						safeAppend,
						placename,
						savestr
					)
					currentlen += 1

					if i ~= length then
						task.wait()
					end
				end
			end
		else
			local totalstr = header
			for _, chunk in chunks do
				totalstr ..= chunk.str
			end
			run_with_loading(
				"Writing " .. get_size_format() .. " to File (Depends on Exec)",
				nil,
				true,
				writefile,
				placename,
				totalstr
			)
		end

		table.clear(SharedStrings.data)
	end

	local Connections
	do
		local Players = service.Players

		if IgnoreList.Model ~= true then
			Connections = {}
			local function ignoreCharacter(player)
				table.insert(
					Connections,
					player.CharacterAdded:Connect(function(character)
						IgnoreList[character] = true
					end)
				)

				local Character = player.Character
				if Character then
					IgnoreList[Character] = true
				end
			end

			if OPTIONS.RemovePlayerCharacters then
				table.insert(
					Connections,
					Players.PlayerAdded:Connect(function(player)
						ignoreCharacter(player)
					end)
				)
				for _, player in Players:GetPlayers() do
					ignoreCharacter(player)
				end
			else
				IgnoreNotArchivable = false
				if IsolateLocalPlayerCharacter then
					task.spawn(function()
						ignoreCharacter(GetLocalPlayer())
					end)
				end
			end
		end
		if IsolateLocalPlayer and IgnoreList.Player ~= true then
			task.spawn(function()
				IgnoreList[GetLocalPlayer()] = true
			end)
		end
	end

	if IsolateStarterPlayer then
		IgnoreList.StarterPlayer = false
	end

	if IsolatePlayers then
		IgnoreList.Players = false
	end

	if OPTIONS.ShowStatus then
		do
			local Exists = GLOBAL_ENV._statustext
			if Exists then
				Exists:Destroy()
			end
		end

		local StatusGui = Instance.new("ScreenGui")

		GLOBAL_ENV._statustext = StatusGui

		StatusGui.DisplayOrder = 2e9
		pcall(function()
			StatusGui.OnTopOfCoreBlur = true
		end)

		StatusText = Instance.new("TextLabel")

		StatusText.Text = "Saving..."

		StatusText.BackgroundTransparency = 1
		StatusText.Font = Enum.Font.Code
		StatusText.AnchorPoint = Vector2.new(1)
		StatusText.Position = UDim2.new(1)
		StatusText.Size = UDim2.new(0.3, 0, 0, 20)

		StatusText.TextColor3 = Color3.new(1, 1, 1)
		StatusText.TextScaled = true
		StatusText.TextStrokeTransparency = 0.7
		StatusText.TextXAlignment = Enum.TextXAlignment.Right
		StatusText.TextYAlignment = Enum.TextYAlignment.Top

		StatusText.Parent = StatusGui

		local function randomString()
			local length = math.random(10, 20)
			local randomarray = table.create(length)
			for i = 1, length do
				randomarray[i] = string.char(math.random(32, 126))
			end
			return table.concat(randomarray)
		end

		if global_container.gethui then
			StatusGui.Name = randomString()
			StatusGui.Parent = global_container.gethui()
		else
			if global_container.protectgui then
				StatusGui.Name = randomString()
				global_container.protectgui(StatusGui)
				StatusGui.Parent = game:GetService("CoreGui")
			else
				local RobloxGui = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
				if RobloxGui then
					StatusGui.Parent = RobloxGui
				else
					StatusGui.Name = randomString()
					StatusGui.Parent = game:GetService("CoreGui")
				end
			end
		end
	end

	do
		local SafeMode = OPTIONS.SafeMode
		if SafeMode then
			task.spawn(function()
				local LocalPlayer = GetLocalPlayer()

				local PlayerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
				if PlayerScripts then
					local function construct_InstanceOverride(instance)
						local children = instance:GetChildren()
						InstancesOverrides[instance] = {
							__Children = children,
						}
						for _, child in children do
							construct_InstanceOverride(child)
						end
					end
					construct_InstanceOverride(PlayerScripts)

					InstancesOverrides[LocalPlayer] = {
						__Children = LocalPlayer:GetChildren(),
						Properties = { Name = "[" .. LocalPlayer.ClassName .. "] " .. LocalPlayer.Name },
					}
				end

				LocalPlayer:Kick("\n[SAFEMODE] Saving in Progress..\nPlease do NOT leave")
				wait_for_render()
				task.delay(10, service.GuiService.ClearError, service.GuiService)
			end)

			service.RunService:Set3dRenderingEnabled(false)
		end

		local anti_idle
		if OPTIONS.AntiIdle then
			task.spawn(function()
				local Idled = GetLocalPlayer().Idled
				if getconnections then
					for _, c in getconnections(Idled) do
						if not pcall(function()
							c:Disable()
						end) then
							pcall(function()
								c:Disconnect()
							end)
						end
					end
				end
				anti_idle = Idled:Connect(function()
					service.VirtualInputManager:SendMouseWheelEvent(
						service.UserInputService:GetMouseLocation().X,
						service.UserInputService:GetMouseLocation().Y,
						true,
						game
					)
				end)
			end)
		end

		elapse_t = os.clock()

		local ok, err = xpcall(save_game, function(err)
			return debug.traceback(err)
		end)

		if SafeMode then
			service.GuiService:ClearError()
			service.RunService:Set3dRenderingEnabled(true)
		end

		if old_gethiddenproperty then
			gethiddenproperty = old_gethiddenproperty
		end

		if anti_idle then
			anti_idle:Disconnect()
		end
		if Connections then
			for _, connection in Connections do
				connection:Disconnect()
			end
		end
		GLOBAL_ENV[placename] = nil
		if StatusText then
			task.spawn(function()
				elapse_t = os.clock() - elapse_t
				local Log10 = math.log10(elapse_t)
				local ExtraTime = 10
				if ok then
					StatusText.Text = string.format("Saved! Time %.3f seconds; Size %s", elapse_t, get_size_format())
					StatusText.TextColor3 = Color3.new(0, 1)
					task.wait(Log10 * 2 + ExtraTime)
				else
					if Loading then
						task.cancel(Loading)
						Loading = nil
					end
					StatusText.Text = "Failed! Check F9 console for more info"
					StatusText.TextColor3 = Color3.new(1)
					warn("Error found while saving:")
					warn(err)
					task.wait(Log10 + ExtraTime)
				end
				StatusText:Destroy()
			end)
		end

		if OPTIONS.ShutdownWhenDone and ok then
			game:Shutdown()
		end
	end
end
print("[USSI] module loaded")  -- ДЕБАГ 0
return synsaveinstance
