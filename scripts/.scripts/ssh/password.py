import argparse
import base64
import getpass
import os
import secrets
from pathlib import Path

from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import padding
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes

SECURE_DIR = Path.home() / ".myssh"
DEFAULT_KEY_FILE = str(SECURE_DIR / "encrypted_key.bin")


class EnhancedPasswordManager:
    """
    文件密钥式密码管理器，使用 AES-CBC 加密。
    """

    def __init__(self, key_file=DEFAULT_KEY_FILE, verbose=False):
        """
        初始化密码管理器。
        :param key_file: 存储加密密钥的文件路径。
        :param verbose: 是否打印详细信息。
        """
        self.key_file = key_file
        self.verbose = verbose

        # 确保密钥所在目录存在，并把权限收窄为仅当前用户可访问
        key_dir = os.path.dirname(os.path.abspath(self.key_file))
        os.makedirs(key_dir, mode=0o700, exist_ok=True)

        if not os.path.exists(self.key_file):
            if self.verbose:
                print(f"密钥文件 '{self.key_file}' 不存在，正在生成随机密钥...")
            self._generate_key()
        elif self.verbose:
            print(f"使用已存在的密钥文件: '{self.key_file}'")

    def _generate_key(self):
        """生成并保存随机 32 字节 AES-256 密钥"""
        key = secrets.token_bytes(32)
        with open(self.key_file, "wb") as f:
            f.write(key)
        os.chmod(self.key_file, 0o600)

    def _get_encryption_key(self):
        """从密钥文件读取加密密钥"""
        with open(self.key_file, "rb") as f:
            return f.read()

    def _pad_data(self, data):
        """填充数据使其符合块大小"""
        padder = padding.PKCS7(128).padder()
        return padder.update(data) + padder.finalize()

    def _unpad_data(self, data):
        """去除填充数据"""
        unpadder = padding.PKCS7(128).unpadder()
        return unpadder.update(data) + unpadder.finalize()

    def encrypt_password(self, real_password):
        """
        加密密码
        :param real_password: 明文字符串
        :return: Base64编码的加密字符串(包含IV)
        """
        key = self._get_encryption_key()
        iv = secrets.token_bytes(16)  # 随机初始化向量

        # 准备加密器
        cipher = Cipher(algorithms.AES(key), modes.CBC(iv), backend=default_backend())
        encryptor = cipher.encryptor()

        # 填充并加密数据
        padded_data = self._pad_data(real_password.encode("utf-8"))
        encrypted_data = encryptor.update(padded_data) + encryptor.finalize()

        # 组合IV和加密数据
        combined = iv + encrypted_data
        return base64.urlsafe_b64encode(combined).decode("ascii")

    def decrypt_to_real_password(self, encrypted_input):
        """
        解密密码
        :param encrypted_input: Base64编码的加密字符串
        :return: 解密后的明文字符串
        """
        key = self._get_encryption_key()
        combined = base64.urlsafe_b64decode(encrypted_input.encode("ascii"))

        # 分离IV和加密数据
        iv = combined[:16]
        encrypted_data = combined[16:]

        # 准备解密器
        cipher = Cipher(algorithms.AES(key), modes.CBC(iv), backend=default_backend())
        decryptor = cipher.decryptor()

        # 解密并去除填充
        decrypted_padded = decryptor.update(encrypted_data) + decryptor.finalize()
        decrypted = self._unpad_data(decrypted_padded)

        return decrypted.decode("utf-8")


def _mask_password(password: str) -> str:
    """
    对密码进行脱敏处理，保留首尾字符，中间用'*'代替。
    例如:
    "123456" -> "12**56"
    "abcde"  -> "ab*de"
    "abcd"   -> "a**d"
    "abc"    -> "a*c"
    "ab"     -> "**"
    "a"      -> "*"
    """
    length = len(password)
    if length <= 2:
        return "*" * length
    if length <= 4:
        return password[0] + "*" * (length - 2) + password[-1]

    # 长度大于4
    return password[:1] + "*" * (length - 2) + password[-1:]


def main():
    """主函数，用于处理命令行参数和执行加解密操作。"""

    parser = argparse.ArgumentParser(
        description="命令行密码加解密工具（密钥存于 ~/.myssh，无主密码）。",
        formatter_class=argparse.RawTextHelpFormatter,
    )

    parser.add_argument(
        "--encrypt",
        type=int,
        default=1,
        choices=[0, 1],
        help="指定操作模式:\n" "  1: 加密 (默认)\n" "  0: 解密",
    )

    parser.add_argument(
        "--keyfile",
        type=str,
        default=DEFAULT_KEY_FILE,
        help=f"指定密钥文件的路径 (默认: {DEFAULT_KEY_FILE})。",
    )

    parser.add_argument(
        "-v", "--verbose", action="store_true", help="显示详细的初始化过程信息。"
    )

    args = parser.parse_args()

    try:
        manager = EnhancedPasswordManager(key_file=args.keyfile, verbose=args.verbose)

        if args.encrypt == 1:
            # --- 加密流程 ---
            while True:
                password_to_encrypt = getpass.getpass("请输入要加密的密码: ")
                if not password_to_encrypt:
                    print("密码不能为空，请重新输入。")
                    continue

                confirm_password = getpass.getpass("请再次输入以确认: ")
                if password_to_encrypt == confirm_password:
                    break
                print("两次输入的密码不匹配，请重试!")

            masked = _mask_password(password_to_encrypt)
            print(f'你输入的密码为: "{masked}"')

            encrypted_data = manager.encrypt_password(password_to_encrypt)
            print("\n加密结果:")
            print(encrypted_data)
        else:
            # --- 解密流程 ---
            password_to_decrypt = input("请输入要解密的字符串: ")
            if not password_to_decrypt:
                print("输入不能为空。")
                return

            decrypted_data = manager.decrypt_to_real_password(password_to_decrypt)
            print("\n解密结果:")
            print(decrypted_data)

    except (ValueError, Exception) as e:
        # 捕获解密失败或其他潜在错误
        print(f"\n操作失败: {e}")


if __name__ == "__main__":
    main()
