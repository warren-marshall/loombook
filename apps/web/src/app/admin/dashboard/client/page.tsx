"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import styles from "./page.module.css";

type ClientRow = {
    id: string;
    companyName: string;
    industry?: string;
    status: "active" | "past" | "churned";
    updatedAt: string;
    updatedByUser?: { firstName: string; lastName: string } | null;
};

const API = process.env.NEXT_PUBLIC_API_URL;

class ApiError extends Error {
    constructor(message: string, readonly status?: number) {
        super(message);
    }
}

async function request(url: string, init?: RequestInit): Promise<Response> {
    let res: Response;
    try {
        res = await fetch(url, init);
    } catch {
        throw new ApiError(`Could not reach the API at ${API}`);
    }
    if (!res.ok) {
        const body = await res.json().catch(() => null);
        throw new ApiError(
            `${url} failed: ${res.status} ${body?.message ?? res.statusText}`,
            res.status,
        );
    }
    return res;
}

async function fetchClients(): Promise<ClientRow[]> {
    const auth = await request(`${API}/api/auth/refresh`, {
        method: "POST",
        credentials: "include",
    });
    const { accessToken } = await auth.json();

    const res = await request(`${API}/api/client`, {
        headers: { Authorization: `Bearer ${accessToken}` },
    });
    return res.json();
}

export default function Client() {
    const router = useRouter();
    const [clients, setClients] = useState<ClientRow[]>([]);
    const [error, setError] = useState("");

    useEffect(() => {
        fetchClients()
            .then(setClients)
            .catch((e: ApiError) => {
                if (e.status === 401) router.replace("/admin/login");
                else setError(e.message);
            });
    }, [router]);

    return <div className={styles.page}>
        <div className={styles.title}>Clients</div>
        <div className={styles.clientList}>
            {error && <p>{error}</p>}
            <table className={styles.table}>
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>Industry</th>
                        <th>Status</th>
                        <th>Last modified</th>
                        <th>Modified by</th>
                    </tr>
                </thead>
                <tbody>
                    {clients.map((c) => (
                        <tr key={c.id}>
                            <td>
                                <Link href={`/admin/dashboard/client/${c.id}`}>
                                    {c.companyName}
                                </Link>
                            </td>
                            <td>{c.industry ?? "—"}</td>
                            <td>{c.status}</td>
                            <td>{new Date(c.updatedAt).toLocaleString()}</td>
                            <td>
                                {c.updatedByUser
                                    ? `${c.updatedByUser.firstName} ${c.updatedByUser.lastName}`
                                    : "—"}
                            </td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    </div>;
}
