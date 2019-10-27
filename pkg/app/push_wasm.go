package app

import (
	"errors"
	"syscall/js"
)

func init() {
	Notifications = pushManager{}
}

type pushManager struct {
}

func (p pushManager) IsSubscribed() bool {
	resChan := make(chan bool)
	defer close(resChan)

	onSub := js.FuncOf(func(this js.Value, args []js.Value) interface{} {
		resChan <- args[0].Truthy()
		return nil
	})
	defer onSub.Release()

	js.Global().
		Get("goappSWRegistration").
		Get("pushManager").
		Call("getSubscription").
		Call("then", onSub)

	return <-resChan
}

func (p pushManager) Subscribe(serverPublicKey string) (string, error) {
	resChan := make(chan string)
	defer close(resChan)

	errChan := make(chan string)
	defer close(errChan)

	onSub := js.FuncOf(func(this js.Value, args []js.Value) interface{} {
		resChan <- js.Global().
			Get("JSON").
			Call("stringify", args[0]).
			String()
		return nil
	})
	defer onSub.Release()

	onErr := js.FuncOf(func(this js.Value, args []js.Value) interface{} {
		errChan <- args[0].Get("message").String()
		return nil
	})
	defer onErr.Release()

	js.Global().
		Get("goappSWRegistration").
		Get("pushManager").
		Call("subscribe", map[string]interface{}{
			"userVisibleOnly":      true,
			"applicationServerKey": js.Global().Call("urlB64ToUint8Array", serverPublicKey),
		}).
		Call("then", onSub).
		Call("catch", onErr)

	select {
	case res := <-resChan:
		return res, nil

	case err := <-errChan:
		return "", errors.New(err)
	}
}

func (p pushManager) UnSubscribe() error {
	panic("not implemented")
}
