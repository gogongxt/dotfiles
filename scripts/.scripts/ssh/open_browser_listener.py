import socket
import threading
import time
import webbrowser


def browser_listener():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("localhost", 7770))
        s.listen()
        print("Listening for browser open commands on port 7770...")

        while True:
            conn, _ = s.accept()
            with conn:
                data = conn.recv(1024).decode().strip()
                if data and data.startswith("http"):
                    print(f"Opening: {data}")
                    webbrowser.open(data)


if __name__ == "__main__":
    # 在后台线程运行监听器
    listener_thread = threading.Thread(target=browser_listener, daemon=True)
    listener_thread.start()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\nListener stopped")
