#!/usr/bin/env python3

import os
import subprocess
from rich import print
from rich.panel import Panel
from openai import OpenAI

LOG_FILE = "/var/log/audit/audit.log"
MODEL = "gpt-4o"
client = OpenAI()

def send_to_chatgpt(log_line):
    response = client.chat.completions.create(
        model=MODEL,
        messages=[
            {
                "role": "system",
                "content": (
                    "You are a professional Linux security engineer. "
                    "For each SELinux denial log provided, output ONLY "
                    "the 'allow' rule required in audit2allow syntax. No explanations."
                )
            },
            {
                "role": "user",
                "content": log_line
            }
        ],
        temperature=0
    )
    return response.choices[0].message.content.strip()

def tail_log():
    process = subprocess.Popen(['tail', '-Fn0', LOG_FILE], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    for line in process.stdout:
        if "avc:  denied" in line:
            print(Panel.fit(f"[bold red]AVC DENIAL DETECTED[/bold red]\n{line.strip()}"))
            print("[bold cyan]--- ChatGPT suggested rule ---[/bold cyan]")
            suggestion = send_to_chatgpt(line)
            print(Panel(suggestion, style="green"))
            print("="*80)

if __name__ == "__main__":
    if "OPENAI_API_KEY" not in os.environ:
        print("[bold red]Error: OPENAI_API_KEY environment variable not set[/bold red]")
        exit(1)
    tail_log()
