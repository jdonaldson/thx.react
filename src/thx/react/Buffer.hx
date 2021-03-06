package thx.react;

#if macro
import haxe.macro.Expr;
using haxe.macro.Context;
using haxe.macro.TypeTools;
using thx.macro.MacroTypes;
#end
using thx.core.Types;

class Buffer 
{
	var queues : Map<String, Array<Dynamic>>;
	var consumers : Map<String, Array<{
		handler : Array<Dynamic> -> Void,
		pos : Int
	}>>;
	public function new()
	{
		queues = new Map();
		consumers = new Map();
	}

	public function queue<T>(value : T)
	{
		queueMany([value]);
	}

	public function queueMany<T>(values : Iterable<T>)
	{
		var names = [];
		for(value in values)
		{
			var name  = Type.typeof(value).toString(),
				queue = ensureQueue(name);
			names.push(name);
			queue.push(value);
		}
		for(name in names)
			trigger(name);
	}

	function ensureQueue(name : String)
	{
		var queue = queues.get(name);
		if(null == queue)
			queues.set(name, queue = []);
		return queue;
	}

#if macro
	public static function getArrayArgumentType(handler : Expr)
	{
		var ftype  = Context.typeof(handler),
			type   = ftype.getArgumentType(0),
			cls    = type.getClass(),
			params = type.getClassTypeParameters();
		return params[0].toString();
	}
#end

	macro public function consume<T>(ethis : ExprOf<Buffer>, handler : Expr)
	{
		var name = getArrayArgumentType(handler);
		return macro $ethis.consumeImpl($v{name}, $handler);
	}

	@:noDoc @:noDisplay
	public function consumeImpl<T>(name : String, handler : Array<T> -> Void)
	{
		var list = consumers.get(name);
		if(null == list)
			consumers.set(name, list = []);
		list.push({ handler : cast handler, pos : 0 });
		trigger(name);
	}

	function trigger(name : String)
	{
		var list = consumers.get(name);
		if(null == list || list.length == 0)
			return;
		var queue = queues.get(name);
		if(null == queue)
			return;
		for(consumer in list)
		{
			var arr = queue.slice(consumer.pos),
				len = arr.length;
			if(len > 0) {
				consumer.handler(arr);
				consumer.pos += len;
			}
		}
	}
}