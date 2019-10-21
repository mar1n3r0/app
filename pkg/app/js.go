package app

// Type represents the JavaScript type of a Value.
type Type int

// Constants that enumerates the JavaScript types.
const (
	TypeUndefined Type = iota
	TypeNull
	TypeBoolean
	TypeNumber
	TypeString
	TypeSymbol
	TypeObject
	TypeFunction
)

// Value is the interface that represents a JavaScript value. On wasm
// architecture, it wraps the https://golang.org/pkg/syscall/js/ package.
type Value interface {
	Bool() bool
	Call(m string, args ...interface{}) Value
	Float() float64
	Get(p string) Value
	Index(i int) Value
	InstanceOf(t Value) bool
	Int() int
	Invoke(args ...interface{}) Value
	JSValue() Value
	Length() int
	New(args ...interface{}) Value
	Set(p string, x interface{})
	SetIndex(i int, x interface{})
	String() string
	Truthy() bool
	Type() Type
}

// Null returns the JavaScript value "null".
func Null() Value {
	panic("not implemented")
}

// Undefined returns the JavaScript value "undefined".
func Undefined() Value {
	panic("not implemented")
}

// ValueOf returns x as a JavaScript value:
//
//  | Go                     | JavaScript             |
//  | ---------------------- | ---------------------- |
//  | js.Value               | [its value]            |
//  | js.Func                | function               |
//  | nil                    | null                   |
//  | bool                   | boolean                |
//  | integers and floats    | number                 |
//  | string                 | string                 |
//  | []interface{}          | new array              |
//  | map[string]interface{} | new object             |
//
// Panics if x is not one of the expected types.
func ValueOf(x interface{}) Value {
	panic("not implemented")
}

// Func is the interface that describes a wrapped Go function to be called by
// JavaScript.
type Func interface {
	Value

	// Release frees up resources allocated for the function. The function must
	// not be invoked after calling Release.
	Release()
}

// FuncOf returns a wrapped function.
//
// Invoking the JavaScript function will synchronously call the Go function fn
// with the value of JavaScript's "this" keyword and the arguments of the
// invocation. The return value of the invocation is the result of the Go
// function mapped back to JavaScript according to ValueOf.
//
// A wrapped function triggered during a call from Go to JavaScript gets
// executed on the same goroutine. A wrapped function triggered by JavaScript's
// event loop gets executed on an extra goroutine. Blocking operations in the
// wrapped function will block the event loop. As a consequence, if one wrapped
// function blocks, other wrapped funcs will not be processed. A blocking
// function should therefore explicitly start a new goroutine.
//
// Func.Release must be called to free up resources when the function will not
// be used any more.
func FuncOf(fn func(this Value, args []Value) interface{}) Func {
	panic("not implemented")
}

// BrowserWindow is the interface that describes the browser window.
type BrowserWindow interface {
	Value

	// The window size.
	Size() (int, int)
}

// Window returns the JavaScript "window" object.
func Window() BrowserWindow {
	panic("not implemented")
}
