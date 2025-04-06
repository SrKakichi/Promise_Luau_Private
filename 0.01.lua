--!strict

type executor = (resolve: (...any) -> never, reject: (...any) -> never) -> ...any;

local NO_VALUE = newproxy();

local ROOT_ENV = "Root";
local THEN_ENV = "Then";
local CATCH_ENV = "Catch";
local FINALLY_ENV = "Finally";

local PENDING = "Pending";
local FULFILLED = "Fulfilled";
local REJECTED = "Rejected";

local INVALID_ARG_TYPE_ERR = "Invalid argument #%s expected '%s' got '%s'.";
local INVALID_STATUS_ERR = "Invalid promise status. Expected status '%s' got '%s'.";
local INDEX_ERR = "Attempt to get invalid key '%s' in '%s'."
local NEW_INDEX_ERR = "Attempt to set key '%s' to value '%s' in '%s'.";

local function pcallAndHandlePromise(node, ...)
	local args = {pcall(node._executor, node._resolveHandler, node._rejectHandler, ...)}
	local ok = args[1];

	if node.status ~= PENDING then return; end;
	if ok then
		node._resolveHandler(select(2, table.unpack(args)));
	else
		node._rejectHandler(select(2, table.unpack(args)));
	end;
end;

-- @class promise
-- a classe base do promise responsável por conter os seus
-- metódos e propriedades herdadas
local promise = {};
promise.__index = promise;

-- @construct promise
function promise.new(executor: executor, env, ...)
	env = env or ROOT_ENV;
	
	assert(typeof(executor) == "function", INVALID_ARG_TYPE_ERR:format(1, "Function", typeof(executor)));
	assert(typeof(env) == "string", INVALID_ARG_TYPE_ERR:format(2, "string", typeof(env)));

	local self = {};

	-- o atual estado do promise que futuramente receberá
	-- FULFILLED ou REJECTED após a conclusão do executor;
	-- o promise SEMPRE deve ser inicializado em PENDING
	self.status = PENDING;

	-- o atual environment desse modelo de promise
	self._env = env;

	-- os atuais nodes que esse promise contém, eles são
	-- injetados por andThen e 
	self._nodes = {};

	self._executor = executor;
	self._args = {...};
	self._result = NO_VALUE;

	-- as funções auxiliares do executor que permitem
	-- a comunicação dele com o promise em si

	setmetatable(self, promise);

	function self._resolveHandler(...)
		self:_resolve(...);
	end;

	function self._rejectHandler(...)
		self:_reject(...);
	end;

	-- se o env for de um promise ROOT_ENV ele executa
	-- por si só sem necessitar de ativação externa
	if env == ROOT_ENV then
		task.spawn(pcallAndHandlePromise, self, ...);
	end;

	return self;
end;

-- define o que acontece quando a Promise é resolvida com sucesso.
---@param onFulfilled function Função a ser chamada quando a Promise for resolvida.
-- @return Promise Retorna uma nova Promise encadeável.
function promise:andThen(onFulfilled: executor)
	assert(typeof(onFulfilled) == "function", INVALID_ARG_TYPE_ERR:format(1, "Function", typeof(onFulfilled)));

	local node = promise.new(onFulfilled, THEN_ENV);
	table.insert(self._nodes, node);

	if self.status == FULFILLED then
		task.spawn(pcallAndHandlePromise, node, table.unpack(self._result));
	end;

	return node;
end;

-- define o que acontece quando a Promise é rejeitada.
-- @param onRejected function Função a ser chamada quando a Promise for rejeitada.
-- @return Promise Retorna uma nova Promise encadeável.
function promise:catch(onRejected: executor)
	assert(typeof(onRejected) == "function", INVALID_ARG_TYPE_ERR:format(1, "Function", typeof(onRejected)));
	
	local node = promise.new(onRejected, CATCH_ENV);
	table.insert(self._nodes, node);

	if self.status == REJECTED then
		task.spawn(pcallAndHandlePromise, node, table.unpack(self._result));
	end;

	return node;
end;

-- define um comportamento que sempre será executado ao final, independentemente do resultado.
-- @param onFinally function Função a ser chamada quando a Promise for concluída.
function promise:finally(onFinally: executor)
	assert(typeof(onFinally) == "function", INVALID_ARG_TYPE_ERR:format(1, "Function", typeof(onFinally)));
	
	local node = promise.new(onFinally, FINALLY_ENV);
	table.insert(self._nodes, node);

	if self.status == FULFILLED or self.status == REJECTED then
		task.spawn(pcallAndHandlePromise, node, table.unpack(self._result));
	end;

	return node;
end;

function promise:_resolve(...)
	if self.status ~= PENDING then
		error(INVALID_STATUS_ERR:format(PENDING, self.status));
	end;

	self._result = {...};
	self.status = FULFILLED;

	for _, node in ipairs(self._nodes) do
		if node._env ~= THEN_ENV and node._env ~= FINALLY_ENV then continue; end;
		task.spawn(pcallAndHandlePromise, node, ...);
	end;
	
	task.delay(1, coroutine.close, coroutine.running());
	return coroutine.yield();
end;

function promise:_reject(...)
	if self.status ~= PENDING then
		error(INVALID_STATUS_ERR:format(PENDING, self.status));
	end;

	self._result = {...};
	self.status = REJECTED;

	for _, node in ipairs(self._nodes) do
		if node._env ~= THEN_ENV and node._env ~= FINALLY_ENV then continue; end;
		task.spawn(pcallAndHandlePromise, node, ...);
	end;

	task.delay(1, coroutine.close, coroutine.running());
	return coroutine.yield();
end;

setmetatable(promise, {
	__index = function(t, k)
		error(INDEX_ERR:format(k, tostring(t)));
	end;
	__newindex = function(t, k, v)
		error(NEW_INDEX_ERR:format(k, v, tostring(t)));
	end;
});

-- retorna a classe de promise pronta para a utilização
return promise;
