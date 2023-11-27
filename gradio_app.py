import gradio as gr
import subprocess
from pathlib import Path

def generate(prompt, model_name="tl-chat.bin", seed=0, temperature=0.5, num_tokens=256):
    base = ""
    tokenizer_name = "tokenizer.bin"
    if model_name == "tl-chat.bin":
        tokenizer_name = 'tok_tl-chat.bin'
    prompt = f"<|im_start|>user\\n{prompt}<|im_end|>\\n<|im_start|>assistant\\n"
    print(f"Executing subprocess with model_name: {model_name}, seed: {seed}, temperature: {temperature}")

    # Note: Subprocess execution is now synchronous
    process = subprocess.run(
        [
            "mojo",
            "llama2.mojo",
            Path(model_name),
            "-s",
            str(seed),
            "-n",
            str(num_tokens),
            "-t",
            str(temperature),
            "-i",
            prompt,
            "-z",
            Path(tokenizer_name)
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )

    if process.stderr:
        print("Subprocess STDERR:", process.stderr)
        return "Error: " + process.stderr

    print("Subprocess STDOUT:", process.stdout)
    return process.stdout

demo = gr.Interface(
    fn=generate,
    inputs=[
        gr.Textbox(label="Prompt"),
        gr.Dropdown(["tl-chat.bin"], label="Model Size", value="tl-chat.bin"),
        gr.Slider(minimum=0, maximum=2**53, value=0, step=1, label="Seed", randomize=True),
        gr.Slider(minimum=0.0, maximum=2.0, step=0.01, value=0.0, label="Temperature"),
        gr.Slider(minimum=1, maximum=500, value=256, label="Number of tokens")
    ],
    outputs="text",
    title="Llama2🔥",
    description="Mojo implementation of llama2.c"
)

if __name__ == "__main__":
    demo.launch(server_name="0.0.0.0")
