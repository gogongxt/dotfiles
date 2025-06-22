import argparse
import os
import base64
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives import padding
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
import getpass
import secrets


class EnhancedPasswordManager:
    """
    增强版密码管理器，使用AES-CBC加密和PBKDF2密钥派生。
    允许任意长度的密码(不推荐使用短密码)。
    """

    def __init__(
        self, key_file="encrypted_key.bin", salt_file="salt.bin", verbose=False
    ):
        """
        初始化密码管理器。
        :param key_file: 存储加密密钥的文件路径。
        :param salt_file: 存储盐值的文件路径。
        :param verbose: 是否打印详细信息。
        """
        self.key_file = key_file
        self.salt_file = salt_file
        self.verbose = verbose

        # 检查并生成必要的文件
        if not os.path.exists(self.salt_file):
            if self.verbose:
                print(f"盐值文件 '{self.salt_file}' 不存在，正在生成...")
            self._generate_salt()

        if not os.path.exists(self.key_file):
            if self.verbose:
                print(f"密钥文件 '{self.key_file}' 不存在，需要创建主密码...")
            self._setup_master_password()
        else:
            if self.verbose:
                print(f"使用已存在的密钥文件: '{self.key_file}'")

    def _generate_salt(self):
        """生成并保存随机盐值"""
        salt = secrets.token_bytes(16)
        with open(self.salt_file, "wb") as f:
            f.write(salt)

    def _get_salt(self):
        """从文件读取盐值"""
        with open(self.salt_file, "rb") as f:
            return f.read()

    def _setup_master_password(self):
        """设置主密码并生成加密密钥"""
        while True:
            master_pwd = getpass.getpass("首次运行，请设置主密码: ")
            confirm = getpass.getpass("请再次输入主密码确认: ")
            if master_pwd == confirm:
                break
            print("两次输入的主密码不匹配，请重试!")

        # 派生加密密钥
        salt = self._get_salt()
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=600000,
            backend=default_backend(),
        )
        key = kdf.derive(master_pwd.encode("utf-8"))

        # 保存加密后的密钥
        with open(self.key_file, "wb") as f:
            f.write(key)
        print("主密码设置成功！")

    def _get_encryption_key(self):
        """验证主密码并返回加密密钥"""
        master_pwd = getpass.getpass("请输入主密码: ")
        salt = self._get_salt()

        # 从主密码派生密钥以进行验证
        kdf_verify = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=600000,
            backend=default_backend(),
        )
        derived_key = kdf_verify.derive(master_pwd.encode("utf-8"))

        # 读取存储的密钥
        with open(self.key_file, "rb") as f:
            stored_key = f.read()

        # 比较派生的密钥和存储的密钥
        if derived_key == stored_key:
            return derived_key
        else:
            # 使用 raise 代替返回 None，可以更清晰地处理错误
            raise ValueError("主密码无效")

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
    
    # 获取脚本文件所在的绝对目录
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # 使用脚本目录构建默认文件路径
    default_key_file = os.path.join(script_dir, "encrypted_key.bin")
    default_salt_file = os.path.join(script_dir, "salt.bin")
    
    parser = argparse.ArgumentParser(
        description="增强版命令行密码加解密工具。",
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
        default=default_key_file,
        help=f"指定密钥文件的路径 (默认: {default_key_file})。",
    )

    parser.add_argument(
        "--saltfile",
        type=str,
        default=default_salt_file,
        help=f"指定盐值文件的路径 (默认: {default_salt_file})。",
    )

    parser.add_argument(
        "-v", "--verbose", action="store_true", help="显示详细的初始化过程信息。"
    )

    args = parser.parse_args()

    try:
        manager = EnhancedPasswordManager(
            key_file=args.keyfile, salt_file=args.saltfile, verbose=args.verbose
        )

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
            print(f"你输入的密码为: \"{masked}\"")

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
