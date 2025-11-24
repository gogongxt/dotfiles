import os
import re
import sys


def clean_log(input_file, output_file=None):
    if output_file is None:
        filename, ext = os.path.splitext(input_file)
        output_file = f"{filename}_clean{ext}"

    try:
        with open(input_file, "r", encoding="utf-8") as f:
            content = f.read()

        # =======================================================
        # 1. 删除 <tool-use> 及其内容 (开启 DOTALL 模式)
        # =======================================================
        # 这里必须允许跨行匹配，因为 tool-use 块通常很长且多行
        tool_use_pattern = r"(?s)<tool-use.*?>.*?</tool-use>"
        content = re.sub(tool_use_pattern, "", content)

        # =======================================================
        # 2. 删除无意义的 Todo 提示块 (开启 DOTALL 模式)
        # =======================================================
        todo_block_pattern = (
            r"(?s)```\s*"
            r"Todos have been modified successfully\."
            r".*?"
            r"Please proceed with the current tasks if applicable"
            r"\s*```"
        )
        content = re.sub(todo_block_pattern, "", content)

        # =======================================================
        # 3. 智能合并连续的 Agent Header (关闭 DOTALL)
        # =======================================================
        agent_header_pattern = r"(_+\*\*Agent(?:\s*\(.*?\))?\*\*_+)"

        # 匹配模式：Header + (纯空白/换行) + Lookahead(Header)
        deduplicate_pattern = f"{agent_header_pattern}\\s+(?={agent_header_pattern})"

        content = re.sub(deduplicate_pattern, "", content)

        # =======================================================
        # 4. 最终格式整理
        # =======================================================
        # 压缩多余空行 (3个以上换行 -> 2个)
        content = re.sub(r"\n{3,}", "\n\n", content)

        with open(output_file, "w", encoding="utf-8") as f:
            f.write(content)

        print(f"✅ 修改完成！已保存至: {output_file}")

    except FileNotFoundError:
        print(f"❌ 错误: 找不到文件 '{input_file}'")
    except Exception as e:
        print(f"❌ 发生错误: {str(e)}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python clean_log.py <输入文件> [输出文件]")
    else:
        input_path = sys.argv[1]
        output_path = sys.argv[2] if len(sys.argv) > 2 else None
        clean_log(input_path, output_path)
