--!strict

---@alias PromiseStates
---| "pending"
---| "fulfilled"
---| "rejected"

local PENDING = "pending"
local FULFILLED = "fulfilled"
local REJECTED = "rejected"

---@class Promise
---@field _state PromiseStates
local promise = {}
promise.__index = promise

--- Cria uma nova instância de Promise.
---@param executor fun(resolve: fun(...), reject: fun(...), ...): (...)? A função executora da promise
---@param parent Promise? Uma promise opcional que pode ser o pai
---@return Promise
function promise.new(executor, parent, ...)
	-- a nova instância de promise
	local self = {}

	function self._resolve(...)
		
	end

	function self._reject(...)
		
	end

	setmetatable(self, promise)

	return self
end

--- Adiciona um manipulador de sucesso à promise.
---@param executor fun(resolve: fun(...), reject: fun(...), ...): (...)? Função executada quando a promise é resolvida
---@return Promise Retorna uma nova promise encadeável
function promise:andThen(executor)
	
end

--- Adiciona um manipulador de erro à promise.
---@param executor fun(resolve: fun(...), reject: fun(...), ...): (...)? Função executada quando a promise é rejeitada
---@return Promise Retorna uma nova promise encadeável
function promise:catch(executor)
	
end

--- Adiciona um manipulador final para quando a promise termina.
---@param executor fun(resolve: fun(...), reject: fun(...), ...): (...)? Função executada independentemente do sucesso ou falha
---@return Promise Retorna uma nova promise encadeável
function promise:finish(executor)
	
end

return promise
