require "stack"
local colorize = require "ansicolor"

OPERATORS = {
	{Symbol = "-", Associativity = "Left", Precedence = 9, Operation = function(stack) return not stack:pop() end},
	{Symbol = "^", Associativity = "Left", Precedence = 8, Operation = function(stack) return stack:pop() and stack:pop() end},
	{Symbol = "v", Associativity = "Left", Precedence = 7, Operation = function(stack) return stack:pop() or stack:pop() end},
	{Symbol = ">", Associativity = "Left", Precedence = 6, Operation = function(stack) local temp = stack:pop() return not stack:pop() or temp end},
	{Symbol = "<", Associativity = "Left", Precedence = 5, Operation = function(stack) return stack:pop() == stack:pop() end},
	{Symbol = "*", Associativity = "Left", Precedence = 4, Operation = function(stack) return stack:pop() ~= stack:pop() end},
}
opID = {}
for k,v in pairs(OPERATORS) do
	opID[v.Symbol] = k
end

function getOperator(symbol)
	return OPERATORS[opID[symbol]]
end
function isOperator(symbol)
	return opID[symbol] ~= nil
end

statements = {}

function toPostfix(statement)
	usedVars = {}
	local opStack = Stack:Create()
	local postfix = ""
	for i = 1, statement:len() do
		local char = statement:sub(i,i)
		if isOperator(char) then
			local operator = getOperator(char)
			if opStack:count() == 0 or opStack:peek() == "(" then
				opStack:push(char)
			else
				local stackOp = getOperator(opStack:peek())
				if operator.Precedence > stackOp.Precedence then
					opStack:push(char)
				else
					while opStack:count() ~= 0 and getOperator(opStack:peek()).Precedence > operator.Precedence do
						postfix = postfix .. opStack:pop()
						opStack:push(char)
					end
				end
			end
		else
			if char == "(" then
				opStack:push(char)
			elseif char == ")" then
				while opStack:peek() ~= "(" do
					postfix = postfix .. opStack:pop()
				end
				opStack:pop()
			else
				--Just a regular operand
				postfix = postfix .. char
				usedVars[char] = true
			end
		end
	end
	for i = 1, opStack:count() do
		postfix = postfix .. opStack:pop()
	end
	return postfix, usedVars
end

function evalPostfix(statement, vars)
	local stack = Stack:Create()
	for i = 1, statement:len() do
		local char = statement:sub(i,i)
		if isOperator(char) then
			operator = getOperator(char)
			local val = operator.Operation(stack)
			stack:push(val)
		else
			stack:push(vars[char])
		end
	end
	return stack:pop()
end

function dumptable(table, depth)
	local depth = depth or 0
	for k,v in pairs(table) do
		local indentation = string.rep("\t", depth)
		if type(v) == "table" then
			print(colorize("%{blue}" .. string.format("%s%s => {", indentation, k)))
			dumptable(v, depth+1)
			print(colorize("%{blue}" .. indentation.."}"))
		else
			print(colorize("%{green}" .. string.format("%s[%s] => %s", indentation, k, v)))
		end
	end
end

function printRes(result)
	for k,v in ipairs(result) do
		print(v.result, table.unpack(v.vars))
	end
end


function computeTable(postfix, vars)
	local result = {}

	local varID = {}
	local varCount = 0
	for k,v in pairs(vars) do
		varCount = varCount + 1
		varID[varCount] = k
	end
	local possible = 2^varCount
	for i = 0, possible-1 do
		local element = {vars = {}}
		for j = 0, varCount-1 do
			local bits = bit32.band(i, 2^j)
			if bit32.rshift(bits, j) == 1 then
				vars[varID[j+1]] = true
			else
				vars[varID[j+1]] = false
			end
			element["vars"][varID[j+1]] = vars[varID[j+1]]
		end
		element["result"] = evalPostfix(postfix, vars)
		table.insert(result, element)
	end
	return result
end

compound = arg[1] or [[p>q]]

local postfix, vars = toPostfix(compound)
solveTable = computeTable(postfix, vars)

if arg[2] then
	local postfix, vars = toPostfix(arg[2])
	checkTable = computeTable(postfix, vars)

	local eq = true

	for k,v in ipairs(checkTable) do
		for sk,sv in ipairs(solveTable) do
			local isSame = true
			for varName, varVal in pairs(v.vars) do
				if sv.vars[varName] ~= varVal then isSame = false end
			end

			if isSame then
				if v.result ~= sv.result then
					eq = false
				end
			end
		end
	end
	print(tostring(eq))
else
	--[[ WIP TABLE LIB
	ta = Grid:Create()
	for k,v in pairs(vars) do
		ta:addColumn(k)
	end
	ta:addColumn(compound)
	for i = 1,#solveTable do
		local row = {}
		for k,v in pairs(solveTable[i].vars) do
			row[k] = solveTable[i].vars[k] and "T" or "F"
		end
		row[compound] = solveTable[i].result and "T" or "F"
		ta:addRow(row)
	end
	ta:draw()
	]]
	dumptable(solveTable)
end
