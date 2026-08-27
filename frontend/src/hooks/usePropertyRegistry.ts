import { useState } from "react";
import { BrowserProvider, Contract } from "ethers";
import { PROPERTY_REGISTRY_ABI, PROPERTY_REGISTRY_ADDRESS, AMOY_CHAIN_ID } from "@/config/propertyRegistry";

type Status = "idle" | "connecting" | "pending" | "confirmed" | "error";

export function usePropertyRegistry() {
    const [status, setStatus] = useState<Status>("idle");
    const [txHash, setTxHash] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);

    async function ensureAmoyNetwork(provider: BrowserProvider) {
    const network = await provider.getNetwork();
        if (network.chainId.toString(16) !== AMOY_CHAIN_ID.replace("0x", "")) {
                await (window as any).ethereum.request({
                method: "wallet_switchEthereumChain",
                params: [{ chainId: AMOY_CHAIN_ID }],
            });
        }
    }

    async function registerOnChain(propertyAddress: string, priceInWei: bigint) {
        if (!(window as any).ethereum) {
            setStatus("error");
            setError("No wallet found — install MetaMask");
            return;
        }

        try {
            setStatus("connecting");
            const provider = new BrowserProvider((window as any).ethereum);
            await provider.send("eth_requestAccounts", []);
            await ensureAmoyNetwork(provider);

            const signer = await provider.getSigner();
            const contract = new Contract(PROPERTY_REGISTRY_ADDRESS, PROPERTY_REGISTRY_ABI, signer);

            setStatus("pending");
            const tx = await contract.registerProperty(propertyAddress, priceInWei);
            setTxHash(tx.hash);

            await tx.wait();
            setStatus("confirmed");
        } catch (err: any) {
            setStatus("error");
            setError(err?.message ?? "Transaction failed");
        }
    }

    return { status, txHash, error, registerOnChain };
}